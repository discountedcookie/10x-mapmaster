import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Tables } from '@/types/database'
import { useAuthStore } from './auth'
import { useEmbeddings } from '@/composables/useEmbeddings'

type Place = Tables<'places'>
type Question = Tables<'questions'>
type GameAnswer = {
  questionId: string
  answer: boolean
  candidatesAfter: number
  candidatesBefore: number
}

// Configuration constants
const LEARNING_RATE = 0.3
const MIN_CONFIDENCE = 0.7
const MAX_QUESTIONS = 5
const INITIAL_CANDIDATES = 20
const MATCH_THRESHOLD = 0.1

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
  const currentQuestionIndex = ref(0)
  const answers = ref<GameAnswer[]>([])
  const gameResult = ref<PlaceWithScore | null>(null)
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)
  const mustAskQuestion = ref(false) // Flag to force asking a question after wrong guess
  // Explicit type to avoid TS2589 type recursion with Supabase Json type
  const questionHistory = ref([] as Array<{ question: string; answer: boolean }>)

  // Computed
  const currentQuestion = computed(() => questions.value[currentQuestionIndex.value])
  const isGameComplete = computed(() => {
    // If we must ask a question (after wrong guess), game is not complete yet
    if (mustAskQuestion.value) {
      return false
    }

    // Complete if we've asked max questions OR confidence is high enough OR no more questions
    const hasReachedMaxQuestions = currentQuestionIndex.value >= MAX_QUESTIONS
    const topCandidate = candidates.value[0]
    const hasHighConfidence = candidates.value.length > 0 && topCandidate && topCandidate.composite_confidence >= MIN_CONFIDENCE
    const noMoreQuestions = currentQuestionIndex.value >= questions.value.length

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
   * Load questions for current session using database context
   */
  async function loadQuestionsForSession() {
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
      currentQuestionIndex.value = 0
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to load questions'
      throw err
    }
  }

  /**
   * Find candidate places using vector similarity search
   */
  async function findCandidatesByEmbedding(embedding: number[]) {
    try {
      loading.value = true
      error.value = undefined

      const { data, error: rpcError } = await supabase
        .rpc('match_places', {
          query_embedding: embeddingToString(embedding),
          match_threshold: MATCH_THRESHOLD,
          match_count: INITIAL_CANDIDATES,
        })

      if (rpcError)
        throw rpcError

      // Type assertion for the RPC return
      const placesWithScore = (data || []) as PlaceWithScore[]
      candidates.value = placesWithScore
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to find candidates'
      throw err
    }
    finally {
      loading.value = false
    }
  }

  /**
   * Refine candidates based on question answer using cumulative filtering.
   *
   * This function implements a progressive narrowing algorithm by maintaining a cumulative
   * history of questions and answers. Each new answer is added to the history, and the full
   * history is sent to the database RPC function which applies semantic + spatial filtering.
   *
   * @param answer - Boolean answer to the current question (true for "Yes", false for "No")
   * @returns Object containing candidatesBefore and candidatesAfter counts for effectiveness tracking
   *
   * @example
   * const { candidatesBefore, candidatesAfter } = await refineCandidates(true)
   * console.log(`Narrowed from ${candidatesBefore} to ${candidatesAfter} candidates`)
   */
  async function refineCandidates(answer: boolean) {
    const question = currentQuestion.value
    if (!question) {
      return { candidatesBefore: candidates.value.length, candidatesAfter: candidates.value.length }
    }

    // Record the state before refinement
    const candidatesBefore = candidates.value.length

    // Get candidate IDs (manual loop to avoid TS2589 type recursion)
    const candidateIds: string[] = []
    for (const candidate of candidates.value) {
      candidateIds.push(candidate.id)
    }

    if (candidateIds.length === 0) {
      return { candidatesBefore: 0, candidatesAfter: 0 }
    }

    // Add current question to history
    questionHistory.value.push({
      question: question.text,
      answer: answer,
    })

    try {
      // Call RPC function with full question history for cumulative filtering
      const { data: filteredCandidates, error: rpcError } = await supabase.rpc('filter_candidates_with_history' as any, {
        candidate_place_ids: candidateIds,
        question_history: questionHistory.value,
      }) as { data: PlaceWithScore[] | null; error: any }

      if (rpcError) {
        console.error('Error filtering candidates:', rpcError)
        // On error, keep all candidates to not break the game
        return { candidatesBefore, candidatesAfter: candidatesBefore }
      }

      // Replace candidates with filtered results (includes updated spatial confidence)
      candidates.value = filteredCandidates || []

      const candidatesAfter = candidates.value.length

      return { candidatesBefore, candidatesAfter }
    }
    catch (err) {
      console.error('Error in refineCandidates:', err)
      // On error, keep all candidates to not break the game
      return { candidatesBefore, candidatesAfter: candidatesBefore }
    }
  }

  /**
   * Answer current question - saves to database and reloads questions
   */
  async function answerQuestion(answer: boolean) {
    if (!currentQuestion.value || !gameSessionId.value)
      return

    const { candidatesBefore, candidatesAfter } = await refineCandidates(answer)

    // Save answer to database IMMEDIATELY
    try {
      const { error: answerError } = await supabase
        .from('game_answers')
        .insert({
          session_id: gameSessionId.value,
          question_id: currentQuestion.value.id,
          answer,
          candidates_after: candidatesAfter,
          sequence_number: answers.value.length + 1,
        })

      if (answerError) {
        console.error('Error saving answer:', answerError)
      }
    }
    catch (err) {
      console.error('Error in answerQuestion:', err)
    }

    // Record answer locally
    answers.value.push({
      questionId: currentQuestion.value.id,
      answer,
      candidatesAfter,
      candidatesBefore,
    })

    // Reload questions from database using session context
    // (Database automatically filters based on answered questions in this session)
    await loadQuestionsForSession()

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
   * Update question effectiveness based on how well it discriminated
   */
  async function updateQuestionEffectiveness(questionId: string, candidatesBefore: number, candidatesAfter: number) {
    try {
      if (candidatesBefore === 0) return

      // Calculate effectiveness: how much did this question reduce candidates?
      const reduction = 1 - (candidatesAfter / candidatesBefore)
      const effectiveness = Math.max(0, Math.min(1, reduction)) // Clamp between 0 and 1

      // Use the database function to update effectiveness
      await supabase.rpc('update_question_effectiveness', {
        question_id_param: questionId,
        new_effectiveness: effectiveness,
      })
    }
    catch (err) {
      console.error('Failed to update question effectiveness:', err)
      // Non-critical error, don't throw
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
          question_count: answers.value.length,
        })
        .eq('id', gameSessionId.value)

      if (sessionError)
        throw sessionError

      // Learning: Update place embedding with new description (only if place already existed)
      // For new places, the embedding was already set during creation with saveNewPlace()
      if (!isNewPlace && actualPlace.embedding && descriptionEmbedding.value) {
        await updatePlaceEmbedding(actualPlace.id, descriptionEmbedding.value)
      }

      // Learning: Update question effectiveness scores
      for (const answer of answers.value) {
        await updateQuestionEffectiveness(
          answer.questionId,
          answer.candidatesBefore,
          answer.candidatesAfter
        )
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
   * 1. Removes the incorrect guess from candidates
   * 2. Forces at least one question to be asked before the next guess (better UX + data collection)
   * 3. Handles edge cases: no remaining candidates, exhausted questions
   *
   * State transitions:
   * - Game result → null (clear incorrect guess)
   * - mustAskQuestion → true (enforce question before next guess)
   * - If no candidates remain → Complete game with "no matches found"
   * - If questions exhausted → Complete game (can't narrow further)
   * - Otherwise → Continue to next question
   *
   * @example
   * // User rejects "Eiffel Tower" guess
   * rejectGuessAndContinue()
   * // Game shows next question instead of immediately guessing again
   */
  function rejectGuessAndContinue() {
    // Remove the top candidate (incorrect guess)
    if (candidates.value.length > 0) {
      candidates.value.shift()
    }

    // Reset game result to continue playing
    gameResult.value = null

    // After a wrong guess, we MUST ask at least one question before guessing again
    // This provides better user engagement and helps narrow down candidates
    mustAskQuestion.value = true

    // Reset question index if it was set to MAX_QUESTIONS (from initial high-confidence guess)
    // This allows us to start asking questions
    if (currentQuestionIndex.value >= questions.value.length) {
      currentQuestionIndex.value = answers.value.length // Resume from where we left off
    }

    // If no candidates left, game is complete with no result
    if (candidates.value.length === 0) {
      mustAskQuestion.value = false
      gameResult.value = null // Will trigger "no matches found" state
      return
    }

    // Check if we've exhausted all available questions
    // If so, we can't ask more questions, so game is complete with no definitive result
    if (currentQuestionIndex.value >= questions.value.length) {
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
    currentQuestionIndex.value = 0
    answers.value = []
    candidates.value = []
    gameResult.value = null
    error.value = undefined
    mustAskQuestion.value = false
    questionHistory.value = []
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
          question_count: 0,
        })
        .select()
        .single()

      if (sessionError)
        throw sessionError

      gameSessionId.value = sessionData.id

      // Find candidates using vector similarity
      await findCandidatesByEmbedding(embedding)

      // Load questions using session context
      await loadQuestionsForSession()

      // Check if we have high confidence right away
      const firstCandidate = candidates.value[0]
      if (firstCandidate && firstCandidate.composite_confidence >= MIN_CONFIDENCE) {
        gameResult.value = firstCandidate
        currentQuestionIndex.value = MAX_QUESTIONS // Skip to end
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
    currentQuestionIndex,
    answers,
    gameResult,
    loading,
    error,

    // Computed
    currentQuestion,
    isGameComplete,
    isLowConfidence,
    topCandidates,
    topCandidate,
    confidence,

    // Actions
    answerQuestion,
    rejectGuessAndContinue,
    finalizeGameSession,
    checkPlaceExists,
    saveNewPlace,
    resetGame,
    startNewGame,
  }
})
