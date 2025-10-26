import { describe, expect, it, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useStatistics, type GameSessionStats } from '@/composables/useStatistics'

// Mock Supabase - use factory function to avoid hoisting issues
vi.mock('@/lib/supabase', () => {
  const mockFrom = vi.fn()
  const mockSelect = vi.fn()
  const mockEq = vi.fn()
  const mockOrder = vi.fn()

  return {
    supabase: {
      from: mockFrom,
    },
    mockFrom,
    mockSelect,
    mockEq,
    mockOrder,
  }
})

// Import mocks after mocking
const { mockFrom, mockSelect, mockEq, mockOrder } = await import('@/lib/supabase') as any

// Mock auth store
const mockUser = { id: 'test-user-id', email: 'test@example.com' }
vi.mock('@/stores/auth', () => ({
  useAuthStore: () => ({
    user: mockUser,
  }),
}))

describe('useStatistics', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()

    // Reset mockUser
    mockUser.id = 'test-user-id'

    // Default mock chain
    mockFrom.mockReturnValue({
      select: mockSelect,
    })
    mockSelect.mockReturnValue({
      eq: mockEq,
    })
    mockEq.mockReturnValue({
      order: mockOrder,
    })
    mockOrder.mockResolvedValue({
      data: [],
      error: null,
    })
  })

  describe('Initial State', () => {
    it('should initialize with empty state', () => {
      const stats = useStatistics()

      expect(stats.loading.value).toBe(false)
      expect(stats.error.value).toBeNull()
      expect(stats.sessions.value).toEqual([])
    })

    it('should have zero statistics initially', () => {
      const stats = useStatistics()

      expect(stats.statistics.value).toEqual({
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        successRate: 0,
        avgQuestionsPerGame: 0,
        avgWrongGuesses: 0,
        totalQuestionsAsked: 0,
        mostRecentGame: null,
      })
    })
  })

  describe('Statistics Calculations', () => {
    it('should calculate basic statistics correctly', () => {
      const stats = useStatistics()

      const sessions: GameSessionStats[] = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test 1',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: false,
          description: 'Test 2',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 10,
          wrong_guess_count: 2,
        },
      ]

      stats.sessions.value = sessions

      expect(stats.statistics.value.gamesPlayed).toBe(2)
      expect(stats.statistics.value.gamesWon).toBe(1)
      expect(stats.statistics.value.gamesLost).toBe(1)
      expect(stats.statistics.value.successRate).toBe(50)
      expect(stats.statistics.value.avgQuestionsPerGame).toBe(7.5)
      expect(stats.statistics.value.avgWrongGuesses).toBe(1)
      expect(stats.statistics.value.totalQuestionsAsked).toBe(15)
      expect(stats.statistics.value.mostRecentGame).toBe('2024-01-01T00:00:00Z')
    })

    it('should calculate 100% success rate', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 3,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.successRate).toBe(100)
    })

    it('should calculate 0% success rate', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 1,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 7,
          wrong_guess_count: 2,
        },
      ]

      expect(stats.statistics.value.successRate).toBe(0)
    })

    it('should exclude incomplete games from success rate', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: null,
          was_correct: null, // Incomplete game
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 2,
          wrong_guess_count: 0,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true, // Complete game
          description: 'Test',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.gamesPlayed).toBe(2)
      expect(stats.statistics.value.gamesWon).toBe(1)
      expect(stats.statistics.value.gamesLost).toBe(0)
      expect(stats.statistics.value.successRate).toBe(100) // 1 win out of 1 completed
    })

    it('should handle all incomplete games', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: null,
          was_correct: null,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 2,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.successRate).toBe(0)
      expect(stats.statistics.value.gamesWon).toBe(0)
      expect(stats.statistics.value.gamesLost).toBe(0)
    })

    it('should calculate averages correctly', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 10,
          wrong_guess_count: 2,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 20,
          wrong_guess_count: 3,
        },
        {
          session_id: '3',
          user_id: 'user-1',
          place_id: 'place-3',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-03T00:00:00Z',
          question_count: 15,
          wrong_guess_count: 1,
        },
      ]

      expect(stats.statistics.value.avgQuestionsPerGame).toBe(15) // (10+20+15)/3
      expect(stats.statistics.value.avgWrongGuesses).toBe(2) // (2+3+1)/3
    })

    it('should pick most recent game date', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-03T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.mostRecentGame).toBe('2024-01-03T00:00:00Z')
    })
  })

  describe('Edge Cases', () => {
    it('should handle single session', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.gamesPlayed).toBe(1)
      expect(stats.statistics.value.successRate).toBe(100)
      expect(stats.statistics.value.avgQuestionsPerGame).toBe(5)
    })

    it('should handle sessions with zero questions', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 0,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.avgQuestionsPerGame).toBe(0)
      expect(stats.statistics.value.totalQuestionsAsked).toBe(0)
    })

    it('should handle sessions with many wrong guesses', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 5,
        },
      ]

      expect(stats.statistics.value.avgWrongGuesses).toBe(5)
    })

    it('should handle large numbers correctly', () => {
      const stats = useStatistics()

      const sessions: GameSessionStats[] = []
      for (let i = 0; i < 100; i++) {
        sessions.push({
          session_id: `${i}`,
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: i % 2 === 0,
          description: 'Test',
          created_at: `2024-01-01T${i.toString().padStart(2, '0')}:00:00Z`,
          question_count: 10,
          wrong_guess_count: 1,
        })
      }

      stats.sessions.value = sessions

      expect(stats.statistics.value.gamesPlayed).toBe(100)
      expect(stats.statistics.value.successRate).toBe(50)
      expect(stats.statistics.value.totalQuestionsAsked).toBe(1000)
    })
  })

  describe('fetchStatistics', () => {
    it('should fetch statistics successfully', async () => {
      const stats = useStatistics()

      const mockData: GameSessionStats[] = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
      ]

      mockOrder.mockResolvedValue({
        data: mockData,
        error: null,
      })

      await stats.fetchStatistics()

      expect(stats.sessions.value).toEqual(mockData)
      expect(stats.loading.value).toBe(false)
      expect(stats.error.value).toBeNull()
    })

    it('should set loading state during fetch', async () => {
      const stats = useStatistics()

      mockOrder.mockImplementation(() => {
        expect(stats.loading.value).toBe(true)
        return Promise.resolve({ data: [], error: null })
      })

      await stats.fetchStatistics()

      expect(stats.loading.value).toBe(false)
    })

    it('should handle fetch errors', async () => {
      const stats = useStatistics()

      const dbError = new Error('Database error')
      mockOrder.mockResolvedValue({
        data: null,
        error: dbError,
      })

      await stats.fetchStatistics()

      expect(stats.error.value).toBe('Database error')
      expect(stats.loading.value).toBe(false)
      expect(stats.sessions.value).toEqual([])
    })

    it('should handle non-Error exceptions', async () => {
      const stats = useStatistics()

      mockOrder.mockRejectedValue('String error')

      await stats.fetchStatistics()

      expect(stats.error.value).toBe('Failed to load statistics')
      expect(stats.loading.value).toBe(false)
    })

    it('should not fetch when user is not authenticated', async () => {
      const stats = useStatistics()
      mockUser.id = undefined as any

      await stats.fetchStatistics()

      expect(stats.error.value).toBe('User not authenticated')
      expect(mockFrom).not.toHaveBeenCalled()
    })

    it('should query with correct parameters', async () => {
      const stats = useStatistics()

      mockOrder.mockResolvedValue({ data: [], error: null })

      await stats.fetchStatistics()

      expect(mockFrom).toHaveBeenCalledWith('game_session_stats')
      expect(mockSelect).toHaveBeenCalledWith('*')
      expect(mockEq).toHaveBeenCalledWith('user_id', 'test-user-id')
      expect(mockOrder).toHaveBeenCalledWith('created_at', { ascending: false })
    })

    it('should handle null data response', async () => {
      const stats = useStatistics()

      mockOrder.mockResolvedValue({
        data: null,
        error: null,
      })

      await stats.fetchStatistics()

      expect(stats.sessions.value).toEqual([])
    })
  })

  describe('Reactivity', () => {
    it('should update statistics when sessions change', () => {
      const stats = useStatistics()

      expect(stats.statistics.value.gamesPlayed).toBe(0)

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 0,
        },
      ]

      expect(stats.statistics.value.gamesPlayed).toBe(1)

      stats.sessions.value.push({
        session_id: '2',
        user_id: 'user-1',
        place_id: 'place-2',
        was_correct: false,
        description: 'Test',
        created_at: '2024-01-02T00:00:00Z',
        question_count: 10,
        wrong_guess_count: 1,
      })

      expect(stats.statistics.value.gamesPlayed).toBe(2)
      expect(stats.statistics.value.successRate).toBe(50)
    })
  })

  describe('Decimal Precision', () => {
    it('should handle decimal averages correctly', () => {
      const stats = useStatistics()

      stats.sessions.value = [
        {
          session_id: '1',
          user_id: 'user-1',
          place_id: 'place-1',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-01T00:00:00Z',
          question_count: 5,
          wrong_guess_count: 1,
        },
        {
          session_id: '2',
          user_id: 'user-1',
          place_id: 'place-2',
          was_correct: false,
          description: 'Test',
          created_at: '2024-01-02T00:00:00Z',
          question_count: 7,
          wrong_guess_count: 2,
        },
        {
          session_id: '3',
          user_id: 'user-1',
          place_id: 'place-3',
          was_correct: true,
          description: 'Test',
          created_at: '2024-01-03T00:00:00Z',
          question_count: 8,
          wrong_guess_count: 0,
        },
      ]

      // (5+7+8)/3 = 6.666...
      expect(stats.statistics.value.avgQuestionsPerGame).toBeCloseTo(6.67, 1)
      // (1+2+0)/3 = 1
      expect(stats.statistics.value.avgWrongGuesses).toBe(1)
      // 2 wins out of 3 completed = 66.666...%
      expect(stats.statistics.value.successRate).toBeCloseTo(66.67, 1)
    })
  })
})
