import { test as base } from '@playwright/test'
import { setupEmbeddingMock } from './mock-embeddings'

/**
 * Extended Playwright test fixture that includes embedding mocking.
 * All E2E tests using this fixture automatically get the embedding mock applied.
 */
export const test = base.extend({
  // Hook into page creation to set up mocking
  page: async ({ page }, use) => {
    // Set up embedding mock before the test runs
    await setupEmbeddingMock(page)

    // Pass the page to the test
    await use(page)
  },
})

// Export expect for assertions
export { expect } from '@playwright/test'
