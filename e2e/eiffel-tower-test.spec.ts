import { test, expect, handleAuth } from './fixtures'

test.describe('Eiffel Tower Scenario', () => {
  test('should handle Eiffel Tower description and complete game flow', async ({ page }) => {
    await page.goto('/')

    // Click "Get Started" button
    await page.getByRole('button', { name: /get started/i }).click()

    // Handle authentication with improved logic
    await handleAuth(page)

    // Enter Eiffel Tower description
    const description =
      'A tall iron tower in a European capital city, iconic landmark you can climb'
    await page.getByPlaceholder(/e.g.,/).fill(description)

    // Start game
    await page.getByRole('button', { name: /start game/i }).click()

    // Wait for loading to complete
    await expect(page.getByText('Analyzing your description...')).toBeVisible()
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should eventually show either a question or a result
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)
    const hasResult = await page
      .getByText(/Is this your place|I'm narrowing it down|No matches found/)
      .isVisible()
      .catch(() => false)

    expect(hasQuestion || hasResult).toBeTruthy()

    // If we got a question, answer it and verify game continues
    if (hasQuestion) {
      // Answer the question
      await page
        .getByRole('button', { name: /yes|no/i })
        .first()
        .click()

      // Should show next state (another question or a result)
      await expect(
        page.getByText(/Question \d+ of|Is this your place|I'm narrowing it down|No matches found/)
      ).toBeVisible({ timeout: 10_000 })
    }

    // Take screenshot of final state
    await page.screenshot({ path: 'test-results/eiffel-tower-final.png' })
  })
})
