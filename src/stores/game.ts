import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { logger } from '@/lib/logger'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database'

type GameSessionStateRow = Database['public']['Views']['game_session_state']['Row']
type GameSessionStatus = Database['public']['Enums']['game_session_status']

export interface PlaceWithScore {
  id: string
  name: string
  lat: number
  lng: number
  confidence: number
  description_similarity: number
  affirmed_trait_similarity: number | null
  denied_trait_similarity: number | null
  geographic_distance: number | null
}

export interface ChatMessage {
  id: string
  role: 'system' | 'user'
  type: 'question' | 'guess' | 'answer' | 'message'
  text: string
  timestamp: Date
  metadata?: {
    questionId?: string
    placeId?: string
    confidence?: number
  }
}

export interface GameState {
  sessionId: string
  description: string
  messages: ChatMessage[]
  candidates: PlaceWithScore[]
  confidence: number
  threshold: number
  semanticConstraint: string
  questionCount: number
  wrongGuessCount: number
  status: GameSessionStatus
  result?: {
    correct_place_id?: string
    guessed_correctly?: boolean
  }
}

export const MAX_QUESTIONS = 5
export const LOW_CONFIDENCE_MIN = 0.5
export const LOW_CONFIDENCE_MAX = 0.8

export function normalizeConfidenceForDisplay(rawScore: number): number {
  return 0.15 + rawScore * 0.8
}

export const useGameStore = defineStore('game', () => {
  // State
  const gameSessionId = ref<string | null>(null)
  const gameState = ref<GameState | null>(null)
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)

  // Display helpers
  const isGameActive = computed(() => gameState.value?.status === 'active')
  const isGameEnded = computed(() =>
    ['won', 'needs_submission', 'ended'].includes(gameState.value?.status || '')
  )
  const isWaitingForPlace = computed(() => gameState.value?.status === 'needs_submission')
  const isNeedsSubmission = computed(() => gameState.value?.status === 'needs_submission')
  const isWon = computed(() => gameState.value?.status === 'won')
  const candidates = computed(() => gameState.value?.candidates ?? [])
  const topCandidates = computed(() => candidates.value.slice(0, 5))
  const displayConfidence = computed(() => gameState.value?.confidence ?? 0)
  const correctPlaceId = computed(() => gameState.value?.result?.correct_place_id ?? null)
  const correctPlace = ref<PlaceWithScore | null>(null)

  // Temporary search results from Nominatim
  const searchResultPlaces = ref<
    Array<{
      id: string
      name: string
      lat: number
      lng: number
    }>
  >([])

  // The place user submitted for pending review
  const submittedPlace = ref<{
    name: string
    lat: number
    lng: number
  } | null>(null)

  // Display state for pending submission
  const isSubmissionPending = computed(
    () => gameState.value?.status === 'ended' && submittedPlace.value !== null
  )

  // Backward compatibility properties
  const questionCount = computed(() => gameState.value?.questionCount ?? 0)
  const currentQuestion = computed(() => {
    const messages = gameState.value?.messages || []
    const lastMessage = messages.at(-1)
    return lastMessage?.type === 'question' ? lastMessage.text : null
  })
  const gameResult = computed(() => {
    if (gameState.value?.status === 'won') {
      return { guessed_correctly: true }
    }
    return null
  })
  const isGameComplete = computed(() => isGameEnded.value)

  function handleError(error_: unknown): string {
    return error_ instanceof Error ? error_.message : 'Unknown error'
  }

  /**
   * Fetch game state from game_session_state view
   * This is the new simplified approach - single query gets all UI data
   */
  async function fetchGameState(sessionId: string): Promise<void> {
    try {
      const { data, error: fetchError } = await supabase
        .from('game_session_state')
        .select('*')
        .eq('session_id', sessionId)
        .single()

      if (fetchError) throw fetchError
      if (!data) throw new Error('No game state found')

      // Convert view row to GameState
      gameState.value = convertViewToGameState(data)
    } catch (error_) {
      logger.error('Failed to fetch game state:', error_)
      throw error_
    }
  }

  /**
   * Convert game_session_state view row to GameState format
   * Builds messages from current question/guess state
   * Extracts candidates directly from next_turn.candidates (no separate RPC call needed)
   */
  function convertViewToGameState(row: GameSessionStateRow): GameState {
    // Status comes directly from database view - no mapping needed
    const status: GameSessionStatus = row.status ?? 'active'

    // Build messages from current state
    const messages: ChatMessage[] = []

    // Parse next_turn JSONB for fallback access to question/guess data
    const nextTurn = row.next_turn as any

    // Try flattened fields first, then fall back to parsing next_turn JSONB
    const questionText = row.current_question_text || nextTurn?.question_text
    const questionId = row.current_question_id || nextTurn?.question_id
    const guessPlaceName = row.pending_guess_place_name || nextTurn?.place_name
    const guessPlaceId = row.pending_guess_place_id || nextTurn?.place_id

    const questionCount = row.question_count ?? 0

    // Add current question if exists
    if (questionText) {
      messages.push({
        id: `question-${questionCount + 1}`,
        role: 'system',
        type: 'question',
        text: questionText,
        timestamp: new Date(),
        metadata: {
          questionId: questionId || undefined,
        },
      })
    }

    // Add pending guess if exists
    if (guessPlaceName) {
      messages.push({
        id: `guess-${questionCount + 1}`,
        role: 'system',
        type: 'guess',
        text: `Is it ${guessPlaceName}?`,
        timestamp: new Date(),
        metadata: {
          placeId: guessPlaceId || undefined,
        },
      })
    }

    // Extract candidates from next_turn.candidates (already populated by database)
    const candidates = (nextTurn?.candidates || []) as PlaceWithScore[]
    const confidence = candidates.length > 0 ? (candidates[0]?.confidence ?? 0) : 0

    // Build result for won games
    const result =
      status === 'won' && row.correct_place_id
        ? {
            correct_place_id: row.correct_place_id,
            guessed_correctly: true,
          }
        : undefined

    return {
      sessionId: row.session_id ?? '',
      description: row.description ?? '',
      messages,
      candidates,
      confidence,
      threshold: 0.92,
      semanticConstraint: '',
      questionCount,
      wrongGuessCount: 0,
      status,
      result,
    }
  }

  // Start new game
  async function startNewGame(description: string, languageCode: string = 'en'): Promise<void> {
    error.value = undefined

    try {
      loading.value = true
      if (!description.trim()) throw new Error('Description cannot be empty')

      // Call RPC - returns only { session_id }
      const { data, error: rpcError } = await supabase.rpc('start_game', {
        p_description: description,
        p_language_code: languageCode,
      })

      if (rpcError) {
        if (rpcError.message?.includes('LLM_UNAVAILABLE')) {
          error.value = 'llm'
        } else if (rpcError.message?.includes('EMBEDDING_UNAVAILABLE')) {
          throw new Error('Embedding service is currently unavailable. Please try again later.')
        } else if (rpcError.message?.includes('description too long')) {
          throw new Error('Description is too long (max 100 characters)')
        } else if (rpcError.message?.includes('invalid control characters')) {
          throw new Error('Description contains invalid characters')
        } else if (rpcError.message?.includes('excessive newlines')) {
          throw new Error('Description contains too many line breaks')
        } else if (rpcError.message?.includes('RATE_LIMITED')) {
          throw new Error('Please wait a few seconds before starting a new game')
        } else if (rpcError.message?.includes('invalid content')) {
          throw new Error('Description contains invalid content')
        } else {
          throw rpcError
        }
      }

      if (!data) throw new Error('No data returned from start_game')

      // start_game returns UUID directly
      const sessionId = typeof data === 'string' ? data : String(data)
      if (!sessionId) throw new Error('No session ID in response')

      gameSessionId.value = sessionId

      // Fetch full game state from view (includes candidates in next_turn)
      await fetchGameState(sessionId)
    } catch (error_) {
      error.value = handleError(error_)
      throw error_
    } finally {
      loading.value = false
    }
  }

  // Play a turn (answer question or guess)
  // Database now extracts trait from question text, no frontend parsing needed
  async function playTurn(answer: boolean): Promise<void> {
    if (!gameSessionId.value) throw new Error('No active game')
    error.value = undefined

    try {
      loading.value = true

      // Call RPC with just session_id and answer (convert boolean to enum value)
      // Database handles trait extraction from question text for semantic questions
      const answerValue = answer ? 'yes' : 'no'
      const { data, error: rpcError } = await supabase.rpc('play_turn', {
        p_session_id: gameSessionId.value,
        p_answer: answerValue as 'yes' | 'no' | 'not_sure',
      })

      if (rpcError) {
        if (rpcError.message?.includes('LLM_UNAVAILABLE')) {
          error.value = 'llm'
        } else if (rpcError.message?.includes('EMBEDDING_UNAVAILABLE')) {
          throw new Error('Embedding service is currently unavailable. Please try again later.')
        } else {
          throw rpcError
        }
      }

      // Fetch updated state from view (includes candidates in next_turn)
      await fetchGameState(gameSessionId.value)
    } catch (error_) {
      error.value = handleError(error_)
      throw error_
    } finally {
      loading.value = false
    }
  }

  // Get current game state (for resuming)
  async function getGameState(): Promise<void> {
    if (!gameSessionId.value) throw new Error('No active game')
    error.value = undefined

    try {
      loading.value = true

      // Fetch from view (includes candidates in next_turn)
      await fetchGameState(gameSessionId.value)
    } catch (error_) {
      error.value = handleError(error_)
      throw error_
    } finally {
      loading.value = false
    }
  }

  // Submit actual place when game fails to guess
  // Uses submit_place RPC which handles place creation/update and session update
  async function submitActualPlace(
    _submittedPlaceName: string,
    _submittedLat: number,
    _submittedLng: number,
    submittedNominatimId: string
  ): Promise<void> {
    if (!gameSessionId.value) throw new Error('No active game')
    error.value = undefined

    try {
      loading.value = true

      // Call submit_place RPC - handles place creation and session update
      const { error: submitError } = await supabase.rpc('submit_place', {
        p_session_id: gameSessionId.value,
        p_osm_id: submittedNominatimId,
      })

      if (submitError) throw submitError

      // Fetch updated state
      await fetchGameState(gameSessionId.value)
    } catch (error_) {
      error.value = handleError(error_)
      throw error_
    } finally {
      loading.value = false
    }
  }

  // Backward compatibility methods
  async function submitAnswer(answerType: string, placeId?: string): Promise<void> {
    if (answerType === 'question_answer') {
      await playTurn(true)
    } else if (answerType === 'wrong_guess' && placeId) {
      await playTurn(false)
    }
  }

  async function finalizeGameSession(_result: any, _correct: boolean): Promise<void> {
    logger.warn('finalizeGameSession is deprecated - handled by playTurn')
  }

  // Reset game state
  function resetGame(): void {
    gameSessionId.value = null
    gameState.value = null
    loading.value = false
    error.value = undefined
  }

  // Add message actions
  function addMessage(
    role: 'system' | 'user',
    text: string,
    type: string,
    metadata?: ChatMessage['metadata']
  ): void {
    if (!gameState.value) return
    const message: ChatMessage = {
      id: `${type}-${Date.now()}`,
      role,
      type: type as ChatMessage['type'],
      text,
      timestamp: new Date(),
      metadata,
    }
    gameState.value.messages.push(message)
  }

  function updateSemanticConstraint(constraint: string): void {
    if (gameState.value) {
      gameState.value.semanticConstraint = constraint
    }
  }

  function updateCandidates(candidates: PlaceWithScore[]): void {
    if (gameState.value) {
      gameState.value.candidates = candidates
      gameState.value.confidence = candidates[0]?.confidence ?? 0
    }
  }

  async function answerQuestion(answer: boolean): Promise<void> {
    await playTurn(answer)

    // Add user message AFTER playTurn completes
    const messages = gameState.value?.messages || []
    const currentMessage = messages.at(-1)
    if (currentMessage && currentMessage.role === 'system') {
      const answerText =
        currentMessage.type === 'guess'
          ? answer
            ? 'Yes, correct!'
            : 'No, try again'
          : answer
            ? 'Yes'
            : 'No'
      addMessage('user', answerText, 'answer')
    }
  }

  // Fetch correct place details when game is won
  async function fetchCorrectPlace(placeId?: string): Promise<void> {
    const targetPlaceId = placeId || correctPlaceId.value

    if (!targetPlaceId) {
      correctPlace.value = null
      return
    }

    try {
      // First check if it's in candidates
      const candidatePlace = candidates.value.find((c) => c.id === targetPlaceId)
      if (candidatePlace) {
        correctPlace.value = candidatePlace
        return
      }

      // Otherwise fetch from database
      const { data, error: fetchError } = await supabase
        .from('places')
        .select('id, name, lat, lng')
        .eq('id', targetPlaceId)
        .single()

      if (fetchError) throw fetchError

      if (data) {
        correctPlace.value = {
          id: data.id,
          name: data.name,
          lat: data.lat ?? 0,
          lng: data.lng ?? 0,
          confidence: 1,
          description_similarity: 1,
          affirmed_trait_similarity: 1,
          denied_trait_similarity: null,
          geographic_distance: null,
        }
      }
    } catch (error_) {
      logger.error('Failed to fetch correct place:', error_)
      correctPlace.value = null
    }
  }

  // Store search results from Nominatim
  function setSearchResultPlaces(places: any[]): void {
    searchResultPlaces.value = places.map((p) => ({
      id: `nominatim-${p.place_id}`,
      name: p.display_name.split(',')[0], // Short name
      lat: parseFloat(p.lat),
      lng: parseFloat(p.lon),
    }))
  }

  // Clear search results
  function clearSearchResultPlaces(): void {
    searchResultPlaces.value = []
  }

  // Store submitted place for display
  function setSubmittedPlace(place: { name: string; lat: number; lng: number }): void {
    submittedPlace.value = place
    searchResultPlaces.value = [] // Clear search results when place is selected
  }

  // Clear submitted place
  function clearSubmittedPlace(): void {
    submittedPlace.value = null
  }

  return {
    gameSessionId,
    gameState,
    loading,
    error,
    isGameActive,
    isGameEnded,
    isWaitingForPlace,
    isNeedsSubmission,
    isWon,
    candidates,
    topCandidates,
    displayConfidence,
    correctPlace,
    correctPlaceId,
    questionCount,
    currentQuestion,
    gameResult,
    isGameComplete,
    searchResultPlaces,
    submittedPlace,
    isSubmissionPending,
    startNewGame,
    playTurn,
    getGameState,
    submitActualPlace,
    submitAnswer,
    finalizeGameSession,
    resetGame,
    addMessage,
    updateSemanticConstraint,
    updateCandidates,
    answerQuestion,
    fetchCorrectPlace,
    setSearchResultPlaces,
    clearSearchResultPlaces,
    setSubmittedPlace,
    clearSubmittedPlace,
  }
})
