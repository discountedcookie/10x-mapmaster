import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Full Game Flow Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should complete full game from start to finish', async ({ page }) => {
    // Start game
    const description = 'A famous landmark in Europe'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer questions progressively
    let questionCount = 0
    while (questionCount < 8) {
      const hasQuestion = await page.getByText(/Question \d+ of/).isVisible()
      const hasGuess = await page.getByText('Is this your place?').isVisible()

      if (hasGuess) {
        // Make final guess
        await page.getByRole('button', { name: "Yes, that's it!" }).click()
        break
      } else if (hasQuestion) {
        // Answer question
        await page.getByRole('button', { name: 'Yes' }).click()
        questionCount++
      } else {
        // Unexpected state
        break
      }
    }

    // Should show win message
    await expect(page.getByText(/Game saved|Correct|You win/i)).toBeVisible()

    // Should offer to play again
    await expect(page.getByRole('button', { name: 'Play Again' })).toBeVisible()
  })

  test('should handle all UI components working together', async ({ page }) => {
    const description = 'A tall structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Verify all components are present and working
    await expect(page.locator('[data-testid="chat-container"]')).toBeVisible()
    await expect(page.locator('[data-testid="confidence-meter"]')).toBeVisible()
    await expect(page.locator('canvas.maplibregl-canvas')).toBeVisible()

    // Answer a few questions
    await page.getByRole('button', { name: 'Yes' }).click()
    await page.getByRole('button', { name: 'No' }).click()

    // Components should still be visible and updated
    await expect(page.locator('[data-testid="chat-container"]')).toBeVisible()
    await expect(page.locator('[data-testid="confidence-meter"]')).toBeVisible()
  })
})
