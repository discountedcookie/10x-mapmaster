import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const MAX_QUESTIONS = 5
export const LOW_CONFIDENCE_MIN = 0.5
export const LOW_CONFIDENCE_MAX = 0.8

export interface GameResult {
  place: {
    id: string
    name: string
    lat: number
    lng: number
  }
  confidence: number
  questionsAsked: number
  userWon: boolean
}

export interface GameCandidate {
  id: string
  name: string
  lat: number
  lng: number
  confidence: number
}

export const useGameStore = defineStore('game', () => {
  // UI State only
  const gameState = ref<'idle' | 'playing' | 'completed'>('idle')
  const currentQuestion = ref<string | null>(null)
  const userDescription = ref('')
  const candidates = ref<GameCandidate[]>([])
  const result = ref<GameResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const questionsAsked = ref(0)

  // Computed
  const isPlaying = computed(() => gameState.value === 'playing')
  const isCompleted = computed(() => gameState.value === 'completed')
  const topCandidates = computed(() => candidates.value.slice(0, 5))
  const topCandidate = computed(() => candidates.value[0] || null)
  const confidence = computed(() => topCandidate.value?.confidence || 0)

  return {
    // State
    gameState,
    currentQuestion,
    userDescription,
    candidates,
    result,
    loading,
    error,
    questionsAsked,

    // Computed
    isPlaying,
    isCompleted,
    topCandidates,
    topCandidate,
    confidence,

    // Actions (UI only - actual logic handled by backend)
    setGameState: (state: 'idle' | 'playing' | 'completed') => {
      gameState.value = state
    },

    setCurrentQuestion: (question: string) => {
      currentQuestion.value = question
    },

    setUserDescription: (description: string) => {
      userDescription.value = description
    },

    setCandidates: (newCandidates: GameCandidate[]) => {
      candidates.value = newCandidates
    },

    setResult: (gameResult: GameResult) => {
      result.value = gameResult
      gameState.value = 'completed'
    },

    setLoading: (isLoading: boolean) => {
      loading.value = isLoading
    },

    setError: (errorMessage: string | null) => {
      error.value = errorMessage
    },

    incrementQuestions: () => {
      questionsAsked.value++
    },

    reset: () => {
      gameState.value = 'idle'
      currentQuestion.value = null
      userDescription.value = ''
      candidates.value = []
      result.value = null
      loading.value = false
      error.value = null
      questionsAsked.value = 0
    }
  }
})

// Keep the utility function for UI
export function normalizeConfidenceForDisplay(rawScore: number): number {
  return 0.15 + (rawScore * 0.80)
}