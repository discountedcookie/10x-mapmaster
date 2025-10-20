import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useEmbeddings } from '@/composables/useEmbeddings'

// Mock environment variables
vi.stubEnv('VITE_SUPABASE_URL', 'http://test.supabase.co')
vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'test-anon-key')

// Mock fetch globally
global.fetch = vi.fn()

describe('useEmbeddings', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('generateEmbedding', () => {
    it('should generate embedding successfully', async () => {
      const mockEmbedding = Array.from({ length: 384 }, () => 0.1)
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ embedding: mockEmbedding }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()
      const result = await generateEmbedding('test description')

      expect(result).toEqual(mockEmbedding)
      expect(result).toHaveLength(384)
    })

    it('should enforce rate limiting between requests', async () => {
      const mockEmbedding = Array.from({ length: 384 }, () => 0.1)
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ embedding: mockEmbedding }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      // First request should succeed
      await generateEmbedding('first')

      // Second request immediately after should fail with rate limit error
      await expect(generateEmbedding('second')).rejects.toThrow(/wait.*second/)
    })

    it('should allow request after cooldown period', async () => {
      const mockEmbedding = Array.from({ length: 384 }, () => 0.1)
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ embedding: mockEmbedding }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      // First request
      await generateEmbedding('first')

      // Advance time by 2 seconds (rate limit period)
      vi.advanceTimersByTime(2000)

      // Second request should now succeed
      const result = await generateEmbedding('second')
      expect(result).toEqual(mockEmbedding)
    })

    it('should throw user-friendly error on 429 status', async () => {
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 429,
        json: async () => ({ error: 'Rate limit exceeded' }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('Too many requests')
    })

    it('should throw user-friendly error on 500+ status', async () => {
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: async () => ({ error: 'Internal server error' }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('Service temporarily unavailable')
    })

    it('should enforce maximum requests per session', async () => {
      const mockEmbedding = Array.from({ length: 384 }, () => 0.1)
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ embedding: mockEmbedding }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      // Make 50 requests (the maximum)
      for (let i = 0; i < 50; i++) {
        await generateEmbedding(`request ${i}`)
        vi.advanceTimersByTime(2000) // Advance to avoid rate limit
      }

      // 51st request should fail
      await expect(generateEmbedding('one too many')).rejects.toThrow(/Too many requests.*refresh/)
    })

    it('should reject invalid embedding dimensions', async () => {
      const invalidEmbedding = Array.from({ length: 256 }, () => 0.1) // Wrong size
      const mockFetch = global.fetch as ReturnType<typeof vi.fn>
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ embedding: invalidEmbedding }),
      } as Response)

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('invalid response')
    })
  })

  describe('embeddingToString', () => {
    it('should convert array to PostgreSQL vector format', () => {
      const { embeddingToString } = useEmbeddings()
      const embedding = [0.1, 0.2, 0.3]

      expect(embeddingToString(embedding)).toBe('[0.1,0.2,0.3]')
    })
  })

  describe('stringToEmbedding', () => {
    it('should parse PostgreSQL vector string to array', () => {
      const { stringToEmbedding } = useEmbeddings()
      const vectorString = '[0.1,0.2,0.3]'

      const result = stringToEmbedding(vectorString)
      expect(result).toEqual([0.1, 0.2, 0.3])
    })
  })
})
