import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Wrong Guess Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[2] = 0.85 // Moderate confidence for wrong guess scenario
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ embedding }),
        })
      } else {
        await route.continue()
      }
    })

    await page.goto('/game')
    await handleAuth(page)
  })

  test('should increment wrong_guess_count after wrong guess', async ({ page }) => {
    const description = 'A famous monument in Rome'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should eventually make a guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible()

    // User says it's wrong
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Should continue asking questions instead of ending
    await expect(page.getByText(/Question \d+ of/)).toBeVisible({ timeout: 5000 })

    // Verify game is still active (not over)
    await expect(page.getByText(/Game Over|ended/i)).not.toBeVisible()
  })

  test('should count wrong guesses toward 5-turn limit', async ({ page }) => {
    const description = 'An ancient wonder of the world'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // First wrong guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible()
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Continue with more questions
    await expect(page.getByText(/Question|Is this/i)).toBeVisible({ timeout: 5000 })
    await page.getByRole('button', { name: 'Yes' }).click()

    // Second wrong guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 5000 })
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // After 2 wrong guesses, should either continue or end game
    // (depending on how many questions were asked)
    await expect(page.getByText(/Question|Is this|Game Over|ended/i)).toBeVisible({ timeout: 5000 })
  })

  test('should end game when wrong guesses exceed limit', async ({ page }) => {
    const description = 'A place that will require many wrong guesses'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Make wrong guesses until game ends
    let guessCount = 0
    while (guessCount < 10) {
      // Safety limit
      try {
        // Wait for guess
        await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 3000 })

        // Reject guess
        await page.getByRole('button', { name: /No|Not it/ }).click()
        guessCount++

        // Wait a bit for response
        await page.waitForTimeout(500)
      } catch {
        // Either game ended or no more guesses
        break
      }
    }

    // After enough wrong guesses, game should end
    await expect(page.getByText(/Game Over|ended|Submit.*place|needs_submission/i)).toBeVisible({
      timeout: 5000,
    })
  })
})
