import { test, expect } from './fixtures'

test.describe('Eiffel Tower Scenario', () => {
  test('should handle Eiffel Tower description and complete game flow', async ({ page }) => {
    await page.goto('/')

    // Click "Get Started" button
    await page.getByRole('button', { name: /get started/i }).click()

    // Handle auth if modal appears
    await page.waitForTimeout(1000)
    const authModalVisible = await page.getByRole('heading', { name: 'Sign In' }).isVisible().catch(() => false)

    if (authModalVisible) {
      // Sign up with test account
      await page.getByText('Need an account? Sign up').click()
      await page.getByPlaceholder('you@example.com').fill(`test-eiffel-${Date.now()}@example.com`)
      await page.getByPlaceholder('••••••••').fill('testpassword123')
      await page.getByRole('button', { name: 'Sign Up' }).click()

      // Wait for auth to complete and modal to disappear
      await expect(page.getByRole('heading', { name: 'Sign In' })).not.toBeVisible({ timeout: 5000 })
    }

    // Enter Eiffel Tower description
    const description = 'A tall iron tower in a European capital city, iconic landmark you can climb'
    await page.getByPlaceholder(/e.g.,/).fill(description)

    // Start game
    await page.getByRole('button', { name: /start game/i }).click()

    // Wait for loading to complete
    await expect(page.getByText('Analyzing your description...')).toBeVisible()
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({ timeout: 15000 })

    // Should eventually show either a question or a result
    const hasQuestion = await page.getByText(/Question \d+ of/).isVisible().catch(() => false)
    const hasResult = await page.getByText(/Is this your place|I'm narrowing it down|No matches found/).isVisible().catch(() => false)

    expect(hasQuestion || hasResult).toBeTruthy()

    // If we got a question, answer it and verify game continues
    if (hasQuestion) {
      // Answer the question
      await page.getByRole('button', { name: /yes|no/i }).first().click()

      // Should show next state (another question or a result)
      await expect(page.getByText(/Question \d+ of|Is this your place|I'm narrowing it down|No matches found/)).toBeVisible({ timeout: 10000 })
    }

    // Take screenshot of final state
    await page.screenshot({ path: 'test-results/eiffel-tower-final.png' })
  })
})
