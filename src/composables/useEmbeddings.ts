import { ref } from 'vue'

/**
 * Get the edge function URL from environment variables.
 * Derives the functions URL from VITE_SUPABASE_URL.
 * For production: uses the production Supabase URL
 * For local dev: typically http://127.0.0.1:54321
 */
function getEdgeFunctionUrl(): string {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
  if (!supabaseUrl) {
    throw new Error('Missing VITE_SUPABASE_URL environment variable')
  }
  return `${supabaseUrl}/functions/v1`
}

export function useEmbeddings() {
    const loading = ref(false)
    const error = ref<string | undefined>(undefined)
    
    // Lazy evaluation: only get URL when needed
    let edgeFunctionUrl: string | null = null
    const getUrl = () => {
      if (!edgeFunctionUrl) {
        edgeFunctionUrl = getEdgeFunctionUrl()
      }
      return edgeFunctionUrl
    }

    // Rate limiting state
    const lastRequestTime = ref<number>(0)
    const requestCount = ref<number>(0)
    const RATE_LIMIT_MS = 2000 // Minimum 2 seconds between requests
    const MAX_REQUESTS_PER_SESSION = 50 // Maximum requests per session

    /**
     * Generate embedding for a given text using the Supabase Edge Function.
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
            throw new Error(`Please wait ${waitTime} second${waitTime > 1 ? 's' : ''} before trying again.`)
        }

        if (requestCount.value >= MAX_REQUESTS_PER_SESSION) {
            throw new Error('Too many requests. Please refresh the page to continue.')
        }

        loading.value = true
        error.value = undefined
        try {
            const response = await fetch(`${getUrl()}/generate-embedding`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
                },
                body: JSON.stringify({ text }),
            })

            if (!response.ok) {
                // User-friendly error messages based on status code
                if (response.status === 429) {
                    throw new Error('Too many requests. Please try again in a moment.')
                } else if (response.status >= 500) {
                    throw new Error('Service temporarily unavailable. Please try again.')
                } else {
                    throw new Error('Unable to process description. Please try again.')
                }
            }

            const data = await response.json()
            if (!Array.isArray(data.embedding) || data.embedding.length !== 384) {
                throw new Error('Received invalid response. Please try again.')
            }

            // Update rate limiting state
            lastRequestTime.value = now
            requestCount.value++

            return data.embedding
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Unable to process description. Please try again.'
            throw err
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
        const cleaned = vectorString.replace(/^\[|\]$/g, '')
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

