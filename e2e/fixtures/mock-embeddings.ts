import { Page } from '@playwright/test'
import crypto from 'node:crypto'

/**
 * Generate a deterministic mock embedding for testing.
 * Same input always produces same output for test reproducibility.
 * Returns a 384-dimensional vector (matching all-MiniLM-L6-v2 model).
 */
export function generateMockEmbedding(text: string): number[] {
  // Create a deterministic seed from the input text
  const hash = crypto.createHash('sha256').update(text).digest()

  // Generate 384-dimensional vector using the hash as seed
  const embedding: number[] = []
  for (let index = 0; index < 384; index++) {
    // Use different bytes of the hash to seed random-like values
    const byteIndex = index % 32
    const byte = hash[byteIndex]

    // Combine with position index for more variation
    const combined = (byte * 37 + index) % 256
    const normalized = (combined / 256) * 2 - 1 // Range: -1 to 1

    embedding.push(Number.parseFloat(normalized.toFixed(6)))
  }

  return embedding
}

/**
 * Set up mocking for the generate-embedding RPC endpoint.
 * Intercepts the HTTP request and returns a mock embedding.
 * This is the endpoint the frontend actually calls via supabase.rpc().
 */
export async function setupEmbeddingMock(page: Page) {
  // Mock the RPC endpoint (what the frontend actually calls)
  await page.route('**/rest/v1/rpc/generate_embedding', async (route) => {
    const request = route.request()

    if (request.method() !== 'POST') {
      await route.continue()
      return
    }

    try {
      const postData = request.postDataJSON()
      const text = postData?.p_text || ''

      if (!text) {
        await route.fulfill({
          status: 400,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'Missing p_text parameter' }),
        })
        return
      }

      const embedding = generateMockEmbedding(text)

      // Return as Supabase RPC response (PostgreSQL vector string format)
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(`[${embedding.join(',')}]`),
      })
    } catch (error) {
      console.error('Error in RPC embedding mock:', error)
      await route.continue()
    }
  })

  // Mock the start_game RPC endpoint
  await page.route('**/rest/v1/rpc/start_game', async (route) => {
    const request = route.request()

    if (request.method() !== 'POST') {
      await route.continue()
      return
    }

    try {
      const postData = request.postDataJSON()
      const description = postData?.p_description || ''

      if (!description) {
        await route.fulfill({
          status: 400,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'Missing p_description parameter' }),
        })
        return
      }

      // Return mock game state
      const mockGameState = {
        session_id: 'mock-session-' + Date.now(),
        status: 'active',
        question_count: 0,
        candidate_count: 100,
        confidence_gap: 0.1,
        candidates: [
          {
            id: 'place-1',
            name: 'Eiffel Tower',
            lat: 48.8584,
            lng: 2.2945,
            semantic_similarity: 0.95,
            spatial_confidence: 0.9,
            composite_confidence: 0.92,
            descriptors: {},
          },
        ],
        next_turn: {
          type: 'question',
          question_text: 'Is this place in Europe?',
          question_type: 'location',
        },
        semantic_constraint: 'A tall iron tower',
        needs_submission: false,
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(mockGameState),
      })
    } catch (error) {
      console.error('Error in start_game mock:', error)
      await route.continue()
    }
  })

  // Keep the existing Edge Function mock for backwards compatibility
  await page.route('**/functions/v1/generate-embedding', async (route) => {
    const request = route.request()

    // Only mock POST requests
    if (request.method() !== 'POST') {
      await route.continue()
      return
    }

    try {
      // Extract text from request body
      const postData = request.postDataJSON()
      const text = postData?.text || ''

      // Generate mock embedding
      const embedding = generateMockEmbedding(text)

      // Return mock response
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ embedding }),
      })
    } catch (error) {
      // If anything goes wrong, continue with real request
      console.error('Error in embedding mock:', error)
      await route.continue()
    }
  })
}
