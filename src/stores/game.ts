import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

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

// Type for game_session_state view
interface GameSessionStateRow {
  session_id: string
  description: string | null
  status: 'active' | 'won' | 'needs_submission' | 'ended_need_actual' | 'expired'
  semantic_constraint: string | null
  current_question_id: string | null
  current_question_text: string | null
  question_type: string | null
  pending_guess_place_id: string | null
  pending_guess_place_name: string | null
  correct_place_id: string | null
  correct_place_name: string | null
  correct_place_lat: number | null
  correct_place_lng: number | null
  question_count: number
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
  status: 'active' | 'won' | 'needs_submission' | 'ended'
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
      console.error('Failed to fetch game state:', error_)
      throw error_
    }
  }

  /**
   * Convert game_session_state view row to GameState format
   * Builds messages from current question/guess state
   * Extracts candidates directly from next_turn.candidates (no separate RPC call needed)
   */
  function convertViewToGameState(row: any): GameState {
    // Map status
    let status: GameState['status'] = 'active'
    switch (row.status) {
      case 'won': {
        status = 'won'
        break
      }
      case 'needs_submission':
      case 'ended_need_actual': {
        status = 'needs_submission'
        break
      }
      case 'expired': {
        status = 'ended'
        break
      }
    }

    // Build messages from current state
    const messages: ChatMessage[] = []

    // Parse next_turn JSONB for fallback access to question/guess data
    const nextTurn = row.next_turn as any

    // Try flattened fields first, then fall back to parsing next_turn JSONB
    const questionText = row.current_question_text || nextTurn?.question_text
    const questionId = row.current_question_id || nextTurn?.question_id
    const guessPlaceName = row.pending_guess_place_name || nextTurn?.place_name
    const guessPlaceId = row.pending_guess_place_id || nextTurn?.place_id

    // Add current question if exists
    if (questionText) {
      messages.push({
        id: `question-${row.question_count + 1}`,
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
        id: `guess-${row.question_count + 1}`,
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
      sessionId: row.session_id,
      description: row.description || '',
      messages,
      candidates,
      confidence,
      threshold: 0.92,
      semanticConstraint: row.semantic_constraint || '',
      questionCount: row.question_count,
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

      // Extract session_id from response
      // start_game returns TABLE(session_id uuid), so Supabase returns an array
      const sessionId = Array.isArray(data) && data.length > 0 ? (data[0] as any).session_id : null
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

      // Call RPC with just session_id and answer
      // Database handles trait extraction from question text for semantic questions
      const { data, error: rpcError } = await supabase.rpc('play_turn', {
        p_session_id: gameSessionId.value,
        p_answer: answer,
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
  async function submitActualPlace(
    submittedPlaceName: string,
    submittedLat: number,
    submittedLng: number,
    submittedNominatimId: string
  ): Promise<void> {
    if (!gameSessionId.value) throw new Error('No active game')
    error.value = undefined

    try {
      loading.value = true

      // Fetch the game session to get the language code
      const { data: sessionData, error: fetchError } = await supabase
        .from('game_sessions')
        .select('description_language_code')
        .eq('id', gameSessionId.value)
        .single()

      if (fetchError) throw fetchError
      const languageCode = sessionData?.description_language_code || 'en'

      // Call add_place RPC
      const { data: placeId, error: addError } = await supabase.rpc('add_place', {
        p_canonical_description: gameState.value?.description || submittedPlaceName,
        p_semantic_constraint: gameState.value?.semanticConstraint || '',
        p_language_code: languageCode,
        p_lat: submittedLat,
        p_lng: submittedLng,
        p_name: submittedPlaceName,
        p_nominatim_place_id: submittedNominatimId,
      })

      if (addError) throw addError

      // Update game session to link to the new place
      const { error: updateError } = await supabase
        .from('game_sessions')
        .update({
          place_id: placeId,
          submitted_place_name: submittedPlaceName,
          submitted_lat: submittedLat,
          submitted_lng: submittedLng,
          submitted_nominatim_id: submittedNominatimId,
          pending_review: false,
          was_correct: false,
        })
        .eq('id', gameSessionId.value)

      if (updateError) throw updateError

      // Update local state
      if (gameState.value) {
        gameState.value.status = 'ended'
      }
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
    console.warn('finalizeGameSession is deprecated - handled by playTurn')
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

  async function guessPlace(placeId: string): Promise<void> {
    console.log('Guess place:', placeId)
  }

  async function submitPlace(name: string, lat: number, lng: number): Promise<void> {
    console.log('Submit place:', name, lat, lng)
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
      console.error('Failed to fetch correct place:', error_)
      correctPlace.value = null
    }
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
    guessPlace,
    submitPlace,
    fetchCorrectPlace,
  }
})
