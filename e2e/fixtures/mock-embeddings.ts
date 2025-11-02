import { Page } from '@playwright/test'
import crypto from 'crypto'

/**
 * Generate a deterministic mock embedding for testing.
 * Same input always produces same output for test reproducibility.
 * Returns a 384-dimensional vector (matching gte-small model).
 */
export function generateMockEmbedding(text: string): number[] {
  // Create a deterministic seed from the input text
  const hash = crypto.createHash('sha256').update(text).digest()

  // Generate 384-dimensional vector using the hash as seed
  const embedding: number[] = []
  for (let i = 0; i < 384; i++) {
    // Use different bytes of the hash to seed random-like values
    const byteIndex = i % 32
    const byte = hash[byteIndex]

    // Combine with position index for more variation
    const combined = (byte * 37 + i) % 256
    const normalized = (combined / 256) * 2 - 1 // Range: -1 to 1

    embedding.push(parseFloat(normalized.toFixed(6)))
  }

  return embedding
}

/**
 * Set up mocking for the generate-embedding edge function.
 * Intercepts the HTTP request and returns a mock embedding.
 */
export async function setupEmbeddingMock(page: Page) {
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
