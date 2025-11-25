import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useEmbeddings } from '@/composables/useEmbeddings'

// Mock the Supabase client
vi.mock('@/lib/supabase', () => {
  const mockRpc = vi.fn()
  return {
    supabase: {
      rpc: mockRpc,
    },
  }
})

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
      const mockEmbedding = Array.from({ length: 1024 }, () => 0.1)
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValueOnce({
        data: `[${mockEmbedding.join(',')}]`,
        error: null,
      })

      const { generateEmbedding } = useEmbeddings()
      const result = await generateEmbedding('test description')

      expect(result).toEqual(mockEmbedding)
      expect(result).toHaveLength(1024)
    })

    it('should enforce rate limiting between requests', async () => {
      const mockEmbedding = Array.from({ length: 1024 }, () => 0.1)
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValue({
        data: `[${mockEmbedding.join(',')}]`,
        error: null,
      })

      const { generateEmbedding } = useEmbeddings()

      // First request should succeed
      await generateEmbedding('first')

      // Second request immediately after should fail with rate limit error
      await expect(generateEmbedding('second')).rejects.toThrow(/wait.*second/)
    })

    it('should allow request after cooldown period', async () => {
      const mockEmbedding = Array.from({ length: 1024 }, () => 0.1)
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValue({
        data: `[${mockEmbedding.join(',')}]`,
        error: null,
      })

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
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValueOnce({
        data: null,
        error: { message: 'Rate limit: 429' },
      })

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('Unable to process description')
    })

    it('should throw user-friendly error on server errors', async () => {
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValueOnce({
        data: null,
        error: { message: 'Internal server error' },
      })

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('Unable to process description')
    })

    it('should enforce maximum requests per session', async () => {
      const mockEmbedding = Array.from({ length: 1024 }, () => 0.1)
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValue({
        data: `[${mockEmbedding.join(',')}]`,
        error: null,
      })

      const { generateEmbedding } = useEmbeddings()

      // Make 50 requests (the maximum)
      for (let index = 0; index < 50; index++) {
        await generateEmbedding(`request ${index}`)
        vi.advanceTimersByTime(2000) // Advance to avoid rate limit
      }

      // 51st request should fail
      await expect(generateEmbedding('one too many')).rejects.toThrow(/Too many requests.*refresh/)
    })

    it('should reject invalid embedding dimensions', async () => {
      const invalidEmbedding = Array.from({ length: 512 }, () => 0.1) // Wrong size (not 1024)
      const { supabase } = await import('@/lib/supabase')
      const mockRpc = supabase.rpc as ReturnType<typeof vi.fn>
      mockRpc.mockResolvedValueOnce({
        data: `[${invalidEmbedding.join(',')}]`,
        error: null,
      })

      const { generateEmbedding } = useEmbeddings()

      await expect(generateEmbedding('test')).rejects.toThrow('Received invalid embedding')
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
