import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Rate Limiting Test', () => {
  test('should enforce 5-second cooldown between games', async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)

    // Start first game
    await page.getByPlaceholder(/e.g.,/).fill('A tower')
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Complete or abandon first game
    await page
      .getByRole('button', { name: 'Start New Game' })
      .or(page.getByRole('button', { name: 'Play Again' }))
      .first()
      .click()

    // Immediately try to start another game
    await page.getByPlaceholder(/e.g.,/).fill('A monument')
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should show rate limit error
    await expect(page.getByText(/rate limit|too soon|wait/i)).toBeVisible()
  })

  test('should allow new game after 5 seconds', async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)

    // Start and complete first game quickly
    await page.getByPlaceholder(/e.g.,/).fill('A building')
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Start new game
    await page.getByRole('button', { name: 'Start New Game' }).click()

    // Wait 5 seconds
    await page.waitForTimeout(5000)

    // Should now allow new game
    await page.getByPlaceholder(/e.g.,/).fill('A statue')
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should proceed without rate limit error
    await expect(page.getByText(/rate limit|too soon/i)).not.toBeVisible()
  })
})
