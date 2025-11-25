import { describe, expect, it, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameState } from '@/composables/game/useGameState'

// Mock the game store with reactive properties
// Using reactive() with getters to mimic Pinia's auto-unwrapping behavior
import { reactive } from 'vue'

const mockStoreState = reactive({
  topCandidates: [] as any[],
  questionCount: 0,
  isGameComplete: false,
  currentQuestion: null as any,
})

// Create computed properties that auto-unwrap (mimics Pinia behavior)
const mockGameStore = {
  get topCandidates() {
    return mockStoreState.topCandidates
  },
  get questionCount() {
    return mockStoreState.questionCount
  },
  get isGameComplete() {
    return mockStoreState.isGameComplete
  },
  get currentQuestion() {
    return mockStoreState.currentQuestion
  },
}

vi.mock('@/stores/game', () => ({
  useGameStore: () => mockGameStore,
}))

describe('useGameState', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()

    // Reset mock store state - modifying reactive object updates all refs
    mockStoreState.topCandidates = []
    mockStoreState.questionCount = 0
    mockStoreState.isGameComplete = false
    mockStoreState.currentQuestion = null
  })

  describe('Initial State', () => {
    it('should initialize with correct default values', () => {
      const state = useGameState()

      expect(state.gameStarted.value).toBe(false)
      expect(state.showResumeDialog.value).toBe(false)
      expect(state.showPlaceSearch.value).toBe(false)
    })

    it('should show start state initially', () => {
      const state = useGameState()

      expect(state.gameState.value).toBe('start')
    })
  })

  describe('hasExistingGame', () => {
    it('should be false when no candidates or questions', () => {
      const state = useGameState()
      mockStoreState.topCandidates = []
      mockStoreState.questionCount = 0

      expect(state.hasExistingGame.value).toBe(false)
    })

    it('should be true when there are candidates', () => {
      const state = useGameState()
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      mockStoreState.questionCount = 0

      expect(state.hasExistingGame.value).toBe(true)
    })

    it('should be true when question count is greater than 0', () => {
      const state = useGameState()
      mockStoreState.topCandidates = []
      mockStoreState.questionCount = 5

      expect(state.hasExistingGame.value).toBe(true)
    })

    it('should be true when both candidates and questions exist', () => {
      const state = useGameState()
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      mockStoreState.questionCount = 5

      expect(state.hasExistingGame.value).toBe(true)
    })
  })

  describe('gameState - State Machine', () => {
    it('should return "resumeDialog" when resume dialog is shown', () => {
      const state = useGameState()
      state.showResumeDialog.value = true

      expect(state.gameState.value).toBe('resumeDialog')
    })

    it('should return "start" when game not started', () => {
      const state = useGameState()
      state.gameStarted.value = false

      expect(state.gameState.value).toBe('start')
    })

    it('should return "placeSearch" when place search is shown', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = true

      expect(state.gameState.value).toBe('placeSearch')
    })

    it('should return "result" when game is complete', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = false
      mockStoreState.isGameComplete = true

      expect(state.gameState.value).toBe('result')
    })

    it('should return "question" when current question exists', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = false
      mockStoreState.isGameComplete = false
      mockStoreState.currentQuestion = { id: 'q1', text: 'Is it in Europe?' }

      expect(state.gameState.value).toBe('question')
    })

    it('should return "idle" when no other conditions match', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = false
      mockStoreState.isGameComplete = false
      mockStoreState.currentQuestion = null

      expect(state.gameState.value).toBe('idle')
    })
  })

  describe('State Priority Order', () => {
    it('should prioritize resumeDialog over all other states', () => {
      const state = useGameState()
      state.showResumeDialog.value = true
      state.gameStarted.value = true
      state.showPlaceSearch.value = true
      mockStoreState.isGameComplete = true
      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }

      expect(state.gameState.value).toBe('resumeDialog')
    })

    it('should prioritize start over other states when game not started', () => {
      const state = useGameState()
      state.gameStarted.value = false
      state.showPlaceSearch.value = true
      mockStoreState.isGameComplete = true

      expect(state.gameState.value).toBe('start')
    })

    it('should prioritize placeSearch over result and question', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = true
      mockStoreState.isGameComplete = true
      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }

      expect(state.gameState.value).toBe('placeSearch')
    })

    it('should prioritize result over question', () => {
      const state = useGameState()
      state.gameStarted.value = true
      state.showPlaceSearch.value = false
      mockStoreState.isGameComplete = true
      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }

      expect(state.gameState.value).toBe('result')
    })
  })

  describe('checkForExistingGame', () => {
    it('should show resume dialog when existing game and not started', () => {
      const state = useGameState()
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      state.gameStarted.value = false

      state.checkForExistingGame()

      expect(state.showResumeDialog.value).toBe(true)
    })

    it('should not show resume dialog when no existing game', () => {
      const state = useGameState()
      mockStoreState.topCandidates = []
      mockStoreState.questionCount = 0
      state.gameStarted.value = false

      state.checkForExistingGame()

      expect(state.showResumeDialog.value).toBe(false)
    })

    it('should not show resume dialog when game already started', () => {
      const state = useGameState()
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      state.gameStarted.value = true

      state.checkForExistingGame()

      expect(state.showResumeDialog.value).toBe(false)
    })

    it('should detect existing game from question count only', () => {
      const state = useGameState()
      mockStoreState.topCandidates = []
      mockStoreState.questionCount = 3
      state.gameStarted.value = false

      state.checkForExistingGame()

      expect(state.showResumeDialog.value).toBe(true)
    })
  })

  describe('Reactivity', () => {
    it('should update gameState when gameStarted changes', () => {
      const state = useGameState()
      expect(state.gameState.value).toBe('start')

      state.gameStarted.value = true
      expect(state.gameState.value).toBe('idle')

      state.gameStarted.value = false
      expect(state.gameState.value).toBe('start')
    })

    it('should update gameState when showResumeDialog changes', () => {
      const state = useGameState()
      state.gameStarted.value = true

      state.showResumeDialog.value = true
      expect(state.gameState.value).toBe('resumeDialog')

      state.showResumeDialog.value = false
      expect(state.gameState.value).toBe('idle')
    })

    it('should update gameState when showPlaceSearch changes', () => {
      const state = useGameState()
      state.gameStarted.value = true

      state.showPlaceSearch.value = true
      expect(state.gameState.value).toBe('placeSearch')

      state.showPlaceSearch.value = false
      expect(state.gameState.value).toBe('idle')
    })

    it('should update gameState when store state changes', () => {
      const state = useGameState()
      state.gameStarted.value = true

      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }
      expect(state.gameState.value).toBe('question')

      mockStoreState.currentQuestion = null
      mockStoreState.isGameComplete = true
      expect(state.gameState.value).toBe('result')
    })
  })

  describe('Game Flow Scenarios', () => {
    it('should handle complete new game flow', () => {
      const state = useGameState()

      // Start: new game
      expect(state.gameState.value).toBe('start')

      // User starts game
      state.gameStarted.value = true
      mockStoreState.currentQuestion = { id: 'q1', text: 'Is it in Europe?' }
      expect(state.gameState.value).toBe('question')

      // Game completes
      mockStoreState.currentQuestion = null
      mockStoreState.isGameComplete = true
      expect(state.gameState.value).toBe('result')
    })

    it('should handle resume game flow', () => {
      const state = useGameState()

      // User has existing game
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      state.checkForExistingGame()
      expect(state.gameState.value).toBe('resumeDialog')

      // User chooses to resume
      state.showResumeDialog.value = false
      state.gameStarted.value = true
      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }
      expect(state.gameState.value).toBe('question')
    })

    it('should handle wrong guess flow requiring place search', () => {
      const state = useGameState()
      state.gameStarted.value = true

      // Game is complete but user rejected the guess
      mockStoreState.isGameComplete = true
      mockStoreState.currentQuestion = null
      expect(state.gameState.value).toBe('result')

      // User says "no, that's wrong" - show place search
      state.showPlaceSearch.value = true
      expect(state.gameState.value).toBe('placeSearch')

      // User selects a place
      state.showPlaceSearch.value = false
      expect(state.gameState.value).toBe('result')
    })
  })

  describe('Edge Cases', () => {
    it('should handle multiple state changes in sequence', () => {
      const state = useGameState()

      state.showResumeDialog.value = true
      expect(state.gameState.value).toBe('resumeDialog')

      state.showResumeDialog.value = false
      expect(state.gameState.value).toBe('start')

      state.gameStarted.value = true
      expect(state.gameState.value).toBe('idle')

      mockStoreState.currentQuestion = { id: 'q1', text: 'Test?' }
      expect(state.gameState.value).toBe('question')
    })

    it('should not interfere with existing game check when already started', () => {
      const state = useGameState()
      mockStoreState.topCandidates = [{ id: 'place-1', name: 'Paris' }]
      state.gameStarted.value = true

      const initialResumeState = state.showResumeDialog.value
      state.checkForExistingGame()

      expect(state.showResumeDialog.value).toBe(initialResumeState)
    })
  })
})
