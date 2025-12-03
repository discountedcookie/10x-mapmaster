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
const { mockFrom, mockSelect, mockEq, mockOrder } = (await import('@/lib/supabase')) as any

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

  describe('Statistics Calculations', () => {
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

      const databaseError = new Error('Database error')
      mockOrder.mockResolvedValue({
        data: null,
        error: databaseError,
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
})
