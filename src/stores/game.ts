import { defineStore } from 'pinia'
import { ref, computed, toRaw } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Tables } from '@/types/database'
import { useAuthStore } from './auth'
import { useEmbeddings } from '@/composables/useEmbeddings'

type Place = Tables<'places'>
type Question = Tables<'questions'>
// Reserved for future use
// type GameAnswer = {
//   questionId: string
//   answer: boolean
//   candidatesAfter: number
//   candidatesBefore: number
// }

// Configuration constants
const LEARNING_RATE = 0.3
const MIN_CONFIDENCE = 0.7
export const MAX_QUESTIONS = 5
// Reserved for future use
const _INITIAL_CANDIDATES = 20
const _MATCH_THRESHOLD = 0.1

// UI confidence thresholds (used by ResultCard)
export const LOW_CONFIDENCE_MIN = 0.5
export const LOW_CONFIDENCE_MAX = 0.8

// Interface for place with similarity and confidence scores
interface PlaceWithScore extends Place {
  semantic_similarity: number
  spatial_confidence: number
  composite_confidence: number
}

export const useGameStore = defineStore('game', () => {
  const authStore = useAuthStore()
  const { generateEmbedding, embeddingToString } = useEmbeddings()

  // State
  const gameSessionId = ref<string | null>(null) // Session ID created at game start
  const userDescription = ref('')
  const descriptionEmbedding = ref<number[] | null>(null)
  const questions = ref<Question[]>([])
  // Explicit type annotation to avoid TS2589 type recursion with Supabase Json type
  const candidates = ref([] as PlaceWithScore[])
  const gameResult = ref<PlaceWithScore | null>(null)
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)
  const mustAskQuestion = ref(false) // Flag to force asking a question after wrong guess
  const sessionQuestionCount = ref(0) // Computed from game_answers, NOT stored in state

  // Computed
  const currentQuestion = computed(() => questions.value[0]) // Always show first available question
  const questionCount = computed(() => sessionQuestionCount.value)
  const isGameComplete = computed(() => {
    // If we must ask a question (after wrong guess), game is not complete yet
    if (mustAskQuestion.value) {
      return false
    }

    // Complete if we've asked max questions OR confidence is high enough OR no more questions
    const hasReachedMaxQuestions = sessionQuestionCount.value >= MAX_QUESTIONS
    const topCandidate = candidates.value[0]
    const hasHighConfidence = candidates.value.length > 0 && topCandidate && topCandidate.composite_confidence >= MIN_CONFIDENCE
    const noMoreQuestions = questions.value.length === 0

    return hasReachedMaxQuestions || hasHighConfidence || noMoreQuestions
  })
  const topCandidates = computed(() => {
    const top5: PlaceWithScore[] = []
    for (let i = 0; i < Math.min(5, candidates.value.length); i++) {
      const candidate = candidates.value[i] as PlaceWithScore | undefined
      if (candidate) top5.push(candidate)
    }
    return top5
  })

  const topCandidate = computed(() => {
    if (candidates.value.length === 0) return null
    return (candidates.value[0] as PlaceWithScore | undefined) ?? null
  })

  const confidence = computed(() => {
    const top = topCandidate.value
    return top?.composite_confidence ?? 0
  })

  const isLowConfidence = computed(() => {
    const top = topCandidate.value
    return top && top.composite_confidence >= 0.5 && top.composite_confidence < 0.8
  })

  /**
   * Load candidates from database using session-first get_candidates RPC
   */
  async function loadCandidates() {
    if (!gameSessionId.value) {
      console.error('Cannot load candidates: no session ID')
      return
    }

    try {
      const { data, error: rpcError } = await supabase.rpc('get_candidates' as any, {
        session_id_param: gameSessionId.value,
      }) as { data: PlaceWithScore[] | null; error: any }

      if (rpcError) {
        console.error('Error loading candidates:', rpcError)
        throw rpcError
      }

      candidates.value = data || []
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to load candidates'
      throw err
    }
  }

  /**
   * Load questions for current session using database context
   */
  async function loadQuestions() {
    if (!gameSessionId.value) {
      console.error('Cannot load questions: no session ID')
      return
    }

    try {
      const { data, error: rpcError } = await supabase.rpc('get_next_question' as any, {
        session_id_param: gameSessionId.value,
        match_count: MAX_QUESTIONS,
      }) as { data: Question[] | null; error: any }

      if (rpcError) {
        console.error('Error loading questions:', rpcError)
        throw rpcError
      }

      questions.value = data || []
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to load questions'
      throw err
    }
  }

  /**
   * Load session state (question count) from database
   */
  async function loadSessionState() {
    if (!gameSessionId.value) return

    try {
      const { data, error: viewError } = await supabase
        .from('game_session_stats' as any)
        .select('question_count, wrong_guess_count')
        .eq('session_id', gameSessionId.value)
        .single()

      if (viewError) {
        console.error('Error loading session state:', viewError)
        return
      }

      sessionQuestionCount.value = (data as any)?.question_count || 0
    }
    catch (err) {
      console.error('Error in loadSessionState:', err)
    }
  }

  /**
   * Answer current question - saves to database, then reloads everything from DB
   */
  async function answerQuestion(answer: boolean) {
    if (!currentQuestion.value || !gameSessionId.value)
      return

    const sequenceNumber = sessionQuestionCount.value + 1

    // Get current candidate IDs and scores for storing in JSONB
    // Use toRaw to strip reactivity and avoid deep type instantiation issue
    const currentCandidates = toRaw(candidates.value)
    const candidatePlaceIds = currentCandidates.map((c: any) => c.id)
    const candidatesAfterData = {
      place_ids: candidatePlaceIds,
      confidence_scores: {
        semantic: currentCandidates[0]?.semantic_similarity || 0,
        spatial: currentCandidates[0]?.spatial_confidence || 0,
        composite: currentCandidates[0]?.composite_confidence || 0,
      },
    }

    // Save answer to database
    try {
      const { error: answerError } = await supabase
        .from('game_answers')
        .insert({
          session_id: gameSessionId.value,
          question_id: currentQuestion.value.id,
          answer,
          answer_type: 'question_answer',
          place_id: null, // NULL for question answers
          candidates_after: candidatesAfterData,
          sequence_number: sequenceNumber,
        })

      if (answerError) {
        console.error('Error saving answer:', answerError)
        throw answerError
      }
    }
    catch (err) {
      console.error('Error in answerQuestion:', err)
      return
    }

    // Reload from DB (candidates and questions update automatically based on new answer)
    await Promise.all([
      loadCandidates(),
      loadQuestions(),
      loadSessionState(),
    ])

    // Clear the mustAskQuestion flag since we've now asked a question
    mustAskQuestion.value = false

    // If game complete, set result to top candidate
    if (isGameComplete.value && candidates.value.length > 0) {
      gameResult.value = (candidates.value[0] as PlaceWithScore | undefined) ?? null
    }
    else if (isGameComplete.value) {
      gameResult.value = null
    }
  }

  /**
   * Add a wrong guess to the session - eliminates place from candidates
   */
  async function submitWrongGuess(placeId: string) {
    if (!gameSessionId.value) return

    const sequenceNumber = sessionQuestionCount.value + 1

    try {
      // Save wrong guess to database
      const { error: guessError } = await supabase
        .from('game_answers')
        .insert({
          session_id: gameSessionId.value,
          question_id: null, // No question for wrong guess
          answer: false,
          answer_type: 'wrong_guess',
          place_id: placeId,
          candidates_after: {
            place_ids: [],
            confidence_scores: { semantic: 0, spatial: 0, composite: 0 },
          },
          sequence_number: sequenceNumber,
        })

      if (guessError) {
        console.error('Error saving wrong guess:', guessError)
        throw guessError
      }

      // Reload candidates (place now eliminated)
      await loadCandidates()

      // Must ask at least one more question
      mustAskQuestion.value = true
    }
    catch (err) {
      console.error('Error in submitWrongGuess:', err)
    }
  }

  /**
   * Update place embedding with weighted average (learning)
   */
  async function updatePlaceEmbedding(placeId: string, newEmbedding: number[]) {
    try {
      await supabase.rpc('update_place_embedding', {
        place_id_param: placeId,
        new_embedding: embeddingToString(newEmbedding),
        learning_rate: LEARNING_RATE,
      })
    }
    catch (err) {
      console.error('Failed to update place embedding:', err)
      throw err
    }
  }

  /**
   * Finalize game session with results and learning updates
   */
  async function finalizeGameSession(actualPlace: Place, wasCorrect: boolean, isNewPlace = false) {
    if (!authStore.user)
      throw new Error('User must be authenticated to save game')

    if (!descriptionEmbedding.value)
      throw new Error('Description embedding is required')

    if (!gameSessionId.value)
      throw new Error('No active game session')

    try {
      loading.value = true
      error.value = undefined

      // Update existing game session with final results
      const { error: sessionError } = await supabase
        .from('game_sessions')
        .update({
          place_id: actualPlace.id,
          was_correct: wasCorrect,
        })
        .eq('id', gameSessionId.value)

      if (sessionError)
        throw sessionError

      // Learning: Update place embedding with new description (only if place already existed)
      // For new places, the embedding was already set during creation with saveNewPlace()
      if (!isNewPlace && actualPlace.embedding && descriptionEmbedding.value) {
        await updatePlaceEmbedding(actualPlace.id, descriptionEmbedding.value)
      }

      // Learning: Update question effectiveness in batch (only if correct)
      if (wasCorrect) {
        await supabase.rpc('update_question_effectiveness_batch', {
          session_id_param: gameSessionId.value,
        })
      }
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to finalize game session'
      throw err
    }
    finally {
      loading.value = false
    }
  }

  /**
   * Check if place exists at given coordinates
   */
  async function checkPlaceExists(lat: number, lng: number): Promise<Place | null> {
    const tolerance = 0.001
    const { data } = await supabase
      .from('places')
      .select('*')
      .gte('lat', lat - tolerance)
      .lte('lat', lat + tolerance)
      .gte('lng', lng - tolerance)
      .lte('lng', lng + tolerance)
      .limit(1)
      .single()

    return data ?? null
  }

  /**
   * Save new place with embedding from user description
   */
  async function saveNewPlace(
    name: string,
    lat: number,
    lng: number,
    descriptors: Record<string, any>
  ): Promise<Place> {
    if (!descriptionEmbedding.value) {
      throw new Error('Description embedding is required to save a new place')
    }

    const { data, error: insertError } = await supabase
      .from('places')
      .insert({
        name,
        lat,
        lng,
        descriptors,
        embedding: embeddingToString(descriptionEmbedding.value),
        game_count: 1, // First occurrence
      })
      .select()
      .single()

    if (insertError)
      throw insertError

    return data
  }

  /**
   * Reject the current guess and continue with remaining candidates.
   *
   * This function implements the state machine logic after a user rejects a guess:
   * 1. Saves wrong guess to database (eliminates from candidates via get_candidates)
   * 2. Forces at least one question to be asked before the next guess (better UX + data collection)
   * 3. Reloads candidates from database (wrong guess automatically filtered out)
   *
   * @example
   * // User rejects "Eiffel Tower" guess
   * await rejectGuessAndContinue()
   * // Game shows next question instead of immediately guessing again
   */
  async function rejectGuessAndContinue() {
    const wrongPlace = gameResult.value
    if (!wrongPlace) return

    // Submit wrong guess (saves to DB and reloads candidates)
    await submitWrongGuess(wrongPlace.id)

    // Reset game result to continue playing
    gameResult.value = null

    // mustAskQuestion is set by submitWrongGuess

    // If no candidates left, game is complete with no result
    if (candidates.value.length === 0) {
      mustAskQuestion.value = false
      gameResult.value = null // Will trigger "no matches found" state
      return
    }

    // Check if we've exhausted all available questions
    // If so, we can't ask more questions, so game is complete with no definitive result
    if (questions.value.length === 0) {
      mustAskQuestion.value = false
      gameResult.value = null // Will trigger "no matches found" state
      return
    }

    // Otherwise, continue with questions (don't immediately show another guess)
    // Game will show next question automatically via isGameComplete computed
    // After answering questions, if confidence is high enough, will show a new guess
  }

  /**
   * Reset game state
   */
  function resetGame() {
    gameSessionId.value = null
    userDescription.value = ''
    descriptionEmbedding.value = null
    candidates.value = []
    questions.value = []
    gameResult.value = null
    error.value = undefined
    mustAskQuestion.value = false
    sessionQuestionCount.value = 0
  }

  /**
   * Start new game with user description - creates session upfront
   */
  async function startNewGame(description: string) {
    if (!authStore.user)
      throw new Error('User must be authenticated to start game')

    try {
      loading.value = true
      error.value = undefined

      // Validate description
      if (!description || description.trim().length === 0) {
        throw new Error('Description cannot be empty')
      }

      // Store description
      userDescription.value = description

      // Generate embedding from description
      const embedding = await generateEmbedding(description)
      descriptionEmbedding.value = embedding

      // Create game session IMMEDIATELY
      const { data: sessionData, error: sessionError } = await supabase
        .from('game_sessions')
        .insert({
          user_id: authStore.user.id,
          description: description,
          description_embedding: embeddingToString(embedding),
          place_id: null, // Will be set when game ends
          was_correct: null, // Will be set when game ends
        })
        .select()
        .single()

      if (sessionError)
        throw sessionError

      gameSessionId.value = sessionData.id

      // Load candidates and questions from DB
      await Promise.all([
        loadCandidates(),
        loadQuestions(),
      ])

      // Check if we have high confidence right away
      const firstCandidate = candidates.value[0]
      if (firstCandidate && firstCandidate.composite_confidence >= MIN_CONFIDENCE) {
        gameResult.value = firstCandidate
      }
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to start game'
      throw err
    }
    finally {
      loading.value = false
    }
  }

  return {
    // State
    gameSessionId,
    userDescription,
    descriptionEmbedding,
    questions,
    candidates,
    gameResult,
    loading,
    error,

    // Computed
    currentQuestion,
    questionCount,
    isGameComplete,
    isLowConfidence,
    topCandidates,
    topCandidate,
    confidence,

    // Actions
    answerQuestion,
    rejectGuessAndContinue,
    submitWrongGuess,
    finalizeGameSession,
    checkPlaceExists,
    saveNewPlace,
    resetGame,
    startNewGame,
    loadCandidates,
    loadQuestions,
    loadSessionState,
  }
})
