import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function useEmbeddings() {
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)

  // Rate limiting state
  const lastRequestTime = ref<number>(0)
  const requestCount = ref<number>(0)
  const RATE_LIMIT_MS = 2000 // Minimum 2 seconds between requests
  const MAX_REQUESTS_PER_SESSION = 50 // Maximum requests per session

  /**
   * Generate embedding for a given text using the database RPC function.
   * Includes client-side rate limiting to prevent API abuse.
   * @param text - The text to embed.
   * @returns Promise<number[]> - The embedding vector.
   */
  async function generateEmbedding(text: string): Promise<number[]> {
    // Check rate limiting
    const now = Date.now()
    const timeSinceLastRequest = now - lastRequestTime.value

    if (timeSinceLastRequest < RATE_LIMIT_MS && lastRequestTime.value > 0) {
      const waitTime = Math.ceil((RATE_LIMIT_MS - timeSinceLastRequest) / 1000)
      throw new Error(
        `Please wait ${waitTime} second${waitTime > 1 ? 's' : ''} before trying again.`
      )
    }

    if (requestCount.value >= MAX_REQUESTS_PER_SESSION) {
      throw new Error('Too many requests. Please refresh the page to continue.')
    }

    loading.value = true
    error.value = undefined
    try {
      // Try database RPC first
      const { data, error: rpcError } = await supabase.rpc('generate_embedding' as any, {
        p_text: text,
      })

      if (rpcError) {
        console.error('generate_embedding RPC error:', rpcError)

        // User-friendly error messages based on error type
        if (rpcError.message?.includes('Embedding generation failed')) {
          throw new Error('Embedding service is currently unavailable. Please try again later.')
        } else if (rpcError.message?.includes('rate limit')) {
          throw new Error('Too many requests. Please try again in a moment.')
        } else if (rpcError.message?.includes('Unknown embedding provider')) {
          throw new Error('Embedding service configuration error. Please contact support.')
        } else if (rpcError.message?.includes('HTTP')) {
          throw new Error('Embedding service network error. Please try again later.')
        } else {
          throw new Error(
            `Unable to process description: ${rpcError.message || 'Unknown error'}. Please try again.`
          )
        }
      }

      if (!data) {
        throw new Error('Received invalid response. Please try again.')
      }

      // Convert vector string to array
      const embedding = stringToEmbedding(data)

      if (embedding.length !== 1024) {
        throw new Error('Received invalid embedding. Please try again.')
      }

      // Update rate limiting state
      lastRequestTime.value = now
      requestCount.value++

      return embedding
    } catch (error_) {
      error.value =
        error_ instanceof Error
          ? error_.message
          : 'Unable to process description. Please try again.'
      throw error_
    } finally {
      loading.value = false
    }
  }

  /**
   * Convert embedding array to PostgreSQL vector format string
   * @param embedding - Array of numbers
   * @returns string - Format: '[0.1,0.2,0.3,...]'
   */
  function embeddingToString(embedding: number[]): string {
    return `[${embedding.join(',')}]`
  }

  /**
   * Parse PostgreSQL vector string to array
   * @param vectorString - String format: '[0.1,0.2,0.3,...]'
   * @returns number[] - Array of numbers
   */
  function stringToEmbedding(vectorString: string): number[] {
    const cleaned = vectorString.replaceAll(/^\[|\]$/g, '')
    return cleaned.split(',').map(Number)
  }

  return {
    generateEmbedding,
    embeddingToString,
    stringToEmbedding,
    loading,
    error,
  }
}
