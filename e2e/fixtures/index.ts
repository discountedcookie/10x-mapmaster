import { test as base, expect as baseExpect, Page } from '@playwright/test'
import { setupEmbeddingMock } from './mock-embeddings'

/**
 * Helper function to handle authentication in E2E tests
 * Waits for page to load, then handles sign-up if needed
 */
async function handleAuth(page: Page) {
  // Wait for page to fully load - check for either game content or auth modal
  await page.waitForLoadState('networkidle')

  // Check if we're already logged in (game page visible)
  const gamePageVisible = await page.getByText('Describe a Place').isVisible({ timeout: 2000 }).catch(() => false)
  if (gamePageVisible) {
    return // Already logged in
  }

  // Check for auth modal - try multiple selectors
  let authVisible = await page.getByRole('heading', { name: 'Sign In' }).isVisible({ timeout: 2000 }).catch(() => false)

  if (authVisible) {
    // Look for sign-up button and click it
    const signUpLink = page.getByText('Need an account? Sign up')
    const signUpLinkVisible = await signUpLink.isVisible({ timeout: 2000 }).catch(() => false)

    if (signUpLinkVisible) {
      await signUpLink.click()
      await page.waitForTimeout(500)
    }

    // Fill in sign-up form
    const emailInput = page.getByPlaceholder('you@example.com')
    const passwordInput = page.getByPlaceholder('••••••••')

    const uniqueEmail = `test-${Date.now()}-${Math.random().toString(36).substring(7)}@example.com`

    await emailInput.fill(uniqueEmail)
    await passwordInput.fill('testpassword123')

    // Click sign up button
    const signUpButton = page.getByRole('button', { name: 'Sign Up' })
    await signUpButton.click()

    // Wait for auth to complete and redirect
    await page.waitForURL('**/game', { timeout: 10000 })
    await page.waitForLoadState('networkidle')
  }

  // Verify we can see the game page
  await baseExpect(page.getByText('Describe a Place')).toBeVisible({ timeout: 10000 })
}

/**
 * Extended Playwright test fixture that includes embedding mocking and auth handling.
 * All E2E tests using this fixture automatically get the embedding mock and auth handling applied.
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

// Export auth helper for tests that need it
export { handleAuth }
