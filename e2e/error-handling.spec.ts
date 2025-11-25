import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Error Handling Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should show error banner when LLM unavailable', async ({ page }) => {
    // Mock LLM failure
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'LLM_UNAVAILABLE' }),
      })
    })

    const description = 'A famous landmark'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should show error banner
    await expect(page.getByText(/unavailable|error/i)).toBeVisible()
  })

  test('should show retry option on embedding failure', async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'EMBEDDING_UNAVAILABLE' }),
      })
    })

    const description = 'A monument'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should show retry button
    await expect(page.getByRole('button', { name: /retry|try again/i })).toBeVisible()
  })

  test('should handle network errors gracefully', async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      await route.abort()
    })

    const description = 'A building'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should show network error message
    await expect(page.getByText(/network|connection|offline/i)).toBeVisible()
  })

  test('should prompt new game when session expired', async ({ page }) => {
    // Mock session expired response
    await page.route('**/rpc/play_turn', async (route) => {
      await route.fulfill({
        status: 410,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Session expired' }),
      })
    })

    const description = 'A structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Try to answer a question
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should prompt for new game
    await expect(page.getByText(/expired|new game/i)).toBeVisible()
  })
})
