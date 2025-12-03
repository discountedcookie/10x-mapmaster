import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameSessionStore } from '@/stores/gameSession'
import type { GameSessionStateRow } from '@/lib/api'

// Mock the API module
vi.mock('@/lib/api', () => ({
  gameApi: {
    startGame: vi.fn(),
    playTurn: vi.fn(),
    getGameState: vi.fn(),
    submitPlace: vi.fn(),
  },
}))

// Import the mocked module
import { gameApi } from '@/lib/api'

describe('useGameSessionStore', () => {
  let store: ReturnType<typeof useGameSessionStore>

  const mockGameSessionStateRow: GameSessionStateRow = {
    session_id: 'session-123',
    description: 'A famous tower',
    status: 'active',
    semantic_constraint: 'tall landmark',
    current_question_id: 'q-1',
    current_question_text: 'Is it in Europe?',
    question_type: 'geographic',
    pending_guess_place_id: null,
    pending_guess_place_name: null,
    correct_place_id: null,
    correct_place_name: null,
    correct_place_lat: null,
    correct_place_lng: null,
    question_count: 1,
    next_turn: {
      action: 'question',
      question_text: 'Is it in Europe?',
      question_id: 'q-1',
      candidates: [],
    },
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    store = useGameSessionStore()
    vi.clearAllMocks()

    // Set up default mocks
    vi.mocked(gameApi.startGame).mockResolvedValue('session-123')
    vi.mocked(gameApi.getGameState).mockResolvedValue(mockGameSessionStateRow)
    vi.mocked(gameApi.playTurn).mockResolvedValue(undefined)
    vi.mocked(gameApi.submitPlace).mockResolvedValue(undefined)
  })

  describe('Initial State', () => {
    it('should initialize with empty state', () => {
      expect(store.session).toBeNull()
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })
  })

  describe('startNewGame', () => {
    it('should call API and store session', async () => {
      await store.startNewGame('A famous tower')

      expect(gameApi.startGame).toHaveBeenCalledWith('A famous tower', 'en')
      expect(gameApi.getGameState).toHaveBeenCalledWith('session-123')
      expect(store.session?.session_id).toBe('session-123')
      expect(store.session?.description).toBe('A famous tower')
      expect(store.session?.status).toBe('active')
      expect(store.loading).toBe(false)
    })

    it('should handle API errors', async () => {
      vi.mocked(gameApi.startGame).mockRejectedValueOnce(new Error('Database error'))

      await store.startNewGame('test')

      expect(store.error).toBe('Database error')
      expect(store.loading).toBe(false)
    })

    it('should handle empty description without calling API', async () => {
      await store.startNewGame('')

      expect(gameApi.startGame).not.toHaveBeenCalled()
      expect(store.error).toBe('Description cannot be empty')
    })

    it('should handle whitespace-only description', async () => {
      await store.startNewGame('   ')

      expect(gameApi.startGame).not.toHaveBeenCalled()
      expect(store.error).toBe('Description cannot be empty')
    })
  })

  describe('answer', () => {
    beforeEach(async () => {
      // Start a game first to have an active session
      await store.startNewGame('A famous tower')
      vi.clearAllMocks()
    })

    it('should call API and update state', async () => {
      const updatedRow = { ...mockGameSessionStateRow, question_count: 2 }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(updatedRow)

      await store.answer(true)

      expect(gameApi.playTurn).toHaveBeenCalledWith('session-123', 'yes')
      expect(gameApi.getGameState).toHaveBeenCalledWith('session-123')
      expect(store.session?.question_count).toBe(2)
      expect(store.loading).toBe(false)
    })

    it('should pass correct answer value for "no"', async () => {
      await store.answer(false)

      expect(gameApi.playTurn).toHaveBeenCalledWith('session-123', 'no')
    })

    it('should require active session', async () => {
      store.resetGame()

      await store.answer(true)

      expect(gameApi.playTurn).not.toHaveBeenCalled()
      expect(store.error).toBe('No active game')
    })

    it('should handle API errors', async () => {
      vi.mocked(gameApi.playTurn).mockRejectedValueOnce(new Error('Network error'))

      await store.answer(true)

      expect(store.error).toBe('Network error')
      expect(store.loading).toBe(false)
    })
  })

  describe('submitPlace', () => {
    beforeEach(async () => {
      // Start a game and set status to needs_submission
      const needsSubmissionRow = { ...mockGameSessionStateRow, status: 'needs_submission' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(needsSubmissionRow)
      await store.startNewGame('A place')
      vi.clearAllMocks()
    })

    it('should submit place to API', async () => {
      const endedRow = { ...mockGameSessionStateRow, status: 'ended' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(endedRow)

      await store.submitPlace('osm-123')

      expect(gameApi.submitPlace).toHaveBeenCalledWith('session-123', 'osm-123')
      expect(gameApi.getGameState).toHaveBeenCalledWith('session-123')
      expect(store.session?.status).toBe('ended')
      expect(store.loading).toBe(false)
    })

    it('should require active session', async () => {
      store.resetGame()

      await store.submitPlace('osm-123')

      expect(gameApi.submitPlace).not.toHaveBeenCalled()
      expect(store.error).toBe('No active game')
    })

    it('should handle API errors', async () => {
      vi.mocked(gameApi.submitPlace).mockRejectedValueOnce(new Error('Submission failed'))

      await store.submitPlace('osm-123')

      expect(store.error).toBe('Submission failed')
      expect(store.loading).toBe(false)
    })
  })

  describe('refresh', () => {
    beforeEach(async () => {
      await store.startNewGame('A famous tower')
      vi.clearAllMocks()
    })

    it('should refresh current session', async () => {
      const updatedRow = { ...mockGameSessionStateRow, question_count: 5 }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(updatedRow)

      await store.refresh()

      expect(gameApi.getGameState).toHaveBeenCalledWith('session-123')
      expect(store.session?.question_count).toBe(5)
    })

    it('should allow refresh with specific session ID', async () => {
      await store.refresh('other-session')

      expect(gameApi.getGameState).toHaveBeenCalledWith('other-session')
    })

    it('should require session when none provided', async () => {
      store.resetGame()

      await store.refresh()

      expect(gameApi.getGameState).not.toHaveBeenCalled()
      expect(store.error).toBe('No active game')
    })
  })

  describe('Game State Management', () => {
    it('should reset game state', async () => {
      await store.startNewGame('test')
      expect(store.session).not.toBeNull()

      store.resetGame()

      expect(store.session).toBeNull()
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })
  })

  describe('Computed Properties', () => {
    it('should derive isGameActive from session status', async () => {
      expect(store.isGameActive).toBe(false)

      await store.startNewGame('test')

      expect(store.isGameActive).toBe(true)
    })

    it('should derive isGameEnded correctly', async () => {
      expect(store.isGameEnded).toBe(false)

      // Test 'won' status
      const wonRow = { ...mockGameSessionStateRow, status: 'won' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(wonRow)
      await store.startNewGame('test')
      expect(store.isGameEnded).toBe(true)

      // Test 'needs_submission' status
      store.resetGame()
      const needsSubmissionRow = { ...mockGameSessionStateRow, status: 'needs_submission' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(needsSubmissionRow)
      await store.startNewGame('test')
      expect(store.isGameEnded).toBe(true)

      // Test 'ended' status
      store.resetGame()
      const endedRow = { ...mockGameSessionStateRow, status: 'ended' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(endedRow)
      await store.startNewGame('test')
      expect(store.isGameEnded).toBe(true)
    })

    it('should derive isNeedsSubmission correctly', async () => {
      expect(store.isNeedsSubmission).toBe(false)

      const needsSubmissionRow = { ...mockGameSessionStateRow, status: 'needs_submission' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(needsSubmissionRow)
      await store.startNewGame('test')

      expect(store.isNeedsSubmission).toBe(true)
    })

    it('should derive isWon correctly', async () => {
      expect(store.isWon).toBe(false)

      const wonRow = { ...mockGameSessionStateRow, status: 'won' as const }
      vi.mocked(gameApi.getGameState).mockResolvedValueOnce(wonRow)
      await store.startNewGame('test')

      expect(store.isWon).toBe(true)
    })
  })
})
