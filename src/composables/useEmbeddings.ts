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
            const { data, error: functionError } = await supabase.functions.invoke('generate-embedding', {
                body: { text },
            })

            if (functionError) {
                // User-friendly error messages based on error type
                if (functionError.message?.includes('429') || functionError.message?.includes('rate limit')) {
                    throw new Error('Too many requests. Please try again in a moment.')
                } else {
                    throw new Error('Unable to process description. Please try again.')
                }
            }

            if (!data || !Array.isArray(data.embedding) || data.embedding.length !== 384) {
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

