import { test as base, expect as baseExpect, Page } from '@playwright/test'
import { setupEmbeddingMock } from './mock-embeddings.js'

/**
 * Helper function to handle authentication in E2E tests
 * Waits for page to load, then handles sign-up if needed
 */
async function handleAuth(page: Page) {
  // Wait for page to fully load
  await page.waitForLoadState('networkidle')

  // Since we mock auth to be logged in, just wait for the game page to load
  await baseExpect(page.getByText('Describe a Place')).toBeVisible({ timeout: 10_000 })
}

/**
 * Extended Playwright test fixture that includes embedding mocking and auth handling.
 * All E2E tests using this fixture automatically get the embedding mock and auth handling applied.
 */
export const test = base.extend({
  // Hook into page creation to set up mocking
  page: async ({ page }, use) => {
    // Set mock auth token in localStorage before app loads
    await page.addInitScript(() => {
      localStorage.setItem(
        'sb-lrrcfzyjtejjbjtoaazm-auth-token',
        JSON.stringify({
          user: {
            id: '1aa6ffda-39d1-454d-baeb-189895b2fe33',
            email: 'test@example.com',
          },
          session: {
            access_token: 'mock-token',
            refresh_token: 'mock-refresh-token',
          },
        })
      )
    })

    // Set up embedding mock before the test runs
    await setupEmbeddingMock(page)

    // Pass the page to the test
    await use(page)
  },
})

// Export expect for assertions
export { expect } from '@playwright/test'

// Export auth helper for tests that need it
export { handleAuth }
