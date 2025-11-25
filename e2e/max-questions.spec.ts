import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Max Turns Test (5 total turns)', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        // Return embedding that keeps multiple candidates throughout
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[3] = 0.6 // Low confidence to force many questions
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

  test('should end game after 5 total turns (questions only)', async ({ page }) => {
    const description = 'A very generic landmark description'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer 5 questions
    for (let index = 1; index <= 5; index++) {
      await expect(page.getByText(`Question ${index} of`)).toBeVisible()
      await page.getByRole('button', { name: Math.random() > 0.5 ? 'Yes' : 'No' }).click()

      // Wait for next question or final guess
      await page.waitForTimeout(500)
    }

    // After 5 turns, should force a final guess or end game
    await expect(page.getByText(/Is this|Final guess|Maximum turns reached/i)).toBeVisible({
      timeout: 5000,
    })
  })

  test('should count wrong guesses toward 5-turn limit', async ({ page }) => {
    const description = 'Something that requires many questions'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer 3 questions
    for (let index = 0; index < 3; index++) {
      try {
        await expect(page.getByText(/Question \d+ of/)).toBeVisible({ timeout: 2000 })
        await page.getByRole('button', { name: 'Yes' }).click()
      } catch {
        break
      }
    }

    // Should eventually reach a guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 5000 })

    // Make 2 wrong guesses (total: 3 questions + 2 wrong guesses = 5 turns)
    for (let index = 0; index < 2; index++) {
      await page.getByRole('button', { name: /No|Not it/ }).click()

      // After first wrong guess, should continue
      if (index === 0) {
        await expect(page.getByText(/Question|Is this/i)).toBeVisible({ timeout: 5000 })
      }
    }

    // After 5 total turns (3 questions + 2 wrong guesses), game should end
    await expect(page.getByText(/Game Over|Maximum turns|ended/i)).toBeVisible({
      timeout: 5000,
    })
  })

  test('should handle user response to forced guess after 5 turns', async ({ page }) => {
    const description = 'Something that requires many questions'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer questions until we reach 5 turns
    let turnCount = 0
    while (turnCount < 7) {
      // Safety limit
      try {
        await expect(page.getByText(/Question \d+ of/)).toBeVisible({
          timeout: 2000,
        })
        await page.getByRole('button', { name: 'Yes' }).click()
        turnCount++
      } catch {
        // No more questions, check for guess
        break
      }
    }

    // Should eventually reach a guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 5000 })

    // User can confirm or deny
    const confirmButton = page.getByRole('button', { name: /Yes|Yeah|That's it/ })
    const rejectButton = page.getByRole('button', { name: /No|Not it/ })

    await expect(confirmButton).toBeVisible()
    await expect(rejectButton).toBeVisible()

    // If wrong, should either go to place submission or end game (depending on turn count)
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Should either show another question, another guess, or game over
    await expect(page.getByText(/Question|Is this|Game Over|Submit.*place/i)).toBeVisible({
      timeout: 5000,
    })
  })
})
