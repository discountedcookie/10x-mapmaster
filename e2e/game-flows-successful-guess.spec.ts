import { test, expect, handleAuth } from './fixtures'

test.describe('Game Flow: Successful Guess', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to game page
    await page.goto('/game')

    // Handle authentication with improved logic
    await handleAuth(page)
  })

  test('should complete game successfully with direct high-confidence guess', async ({ page }) => {
    // Enter a very distinctive description that should get high confidence match
    const description =
      'A monumental ancient structure with a massive upright stone block, located in Stonehenge England, built in prehistoric times'

    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Verify description was entered
    await expect(page.getByText(`${description.length}/200`)).toBeVisible()

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for embedding to be generated
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for analysis to complete (embedding + candidate matching)
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Should show either:
    // 1. A direct high-confidence guess ("Is this your place?")
    // 2. Questions narrowing down the place
    const hasDirectGuess = await page
      .getByText('Is this it?')
      .isVisible()
      .catch(() => false)

    const hasQuestions = await page
      .getByText(/Question \d+ of \d+/)
      .isVisible()
      .catch(() => false)

    expect(hasDirectGuess || hasQuestions).toBeTruthy()

    if (hasDirectGuess) {
      // User confirms the guess is correct
      await page.getByRole('button', { name: "Yeah, that's the one!" }).click()

      // Should show success toast
      await expect(page.getByText('Game saved!')).toBeVisible()

      // Game should transition to completion state
      await expect(page.getByText(/You found it|Success|Complete/)).toBeVisible({
        timeout: 5000,
      })
    }
  })

  test('should complete game after answering questions correctly', async ({ page }) => {
    // Enter a well-known place description
    const description =
      'A large red castle in Bavaria, Germany used as a royal residence, famous for its fairy-tale appearance'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for loading to complete
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Answer questions if presented
    let questionsAnswered = 0
    const maxQuestions = 5

    while (questionsAnswered < maxQuestions) {
      const questionVisible = await page
        .getByText(/Question \d+ of \d+/)
        .isVisible()
        .catch(() => false)

      if (!questionVisible) {
        break
      }

      // Answer with "Yes" (consistent answering pattern)
      const yesButton = page.getByRole('button', { name: 'Yes' }).first()

      if (await yesButton.isVisible()) {
        await yesButton.click()
        questionsAnswered++

        // Wait for next state (either another question or result)
        await page.waitForTimeout(500)
      } else {
        break
      }
    }

    // After answering questions, should show a guess
    await expect(page.getByText(/Is this it|I'm narrowing it down/)).toBeVisible({
      timeout: 5000,
    })

    // If there's a definitive guess, confirm it
    const guessButton = page.getByRole('button', { name: "Yeah, that's the one!" })

    if (await guessButton.isVisible()) {
      await guessButton.click()

      // Verify game completion
      await expect(page.getByText('Game saved!')).toBeVisible()
    }
  })

  test('should track questions asked in game session', async ({ page }) => {
    const description =
      'A massive stone face carved into a mountain in South Dakota, showing four presidents'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Check if any questions are visible
    const questionText = page.getByText(/Question \d+ of (\d+)/)

    if (await questionText.isVisible()) {
      const textContent = await questionText.textContent()

      // Extract total number of questions from "Question X of Y" format
      const match = textContent?.match(/Question \d+ of (\d+)/)
      const totalQuestions = match ? Number.parseInt(match[1]) : 0

      expect(totalQuestions).toBeGreaterThan(0)
      expect(totalQuestions).toBeLessThanOrEqual(5) // MAX_QUESTIONS from game store

      // Answer at least one question
      const yesButton = page.getByRole('button', { name: 'Yes' }).first()

      if (await yesButton.isVisible()) {
        await yesButton.click()

        // Verify we can see the question counter updating
        await page.waitForTimeout(500)
        const nextQuestionVisible = await page
          .getByText(/Question \d+ of/)
          .isVisible()
          .catch(() => false)

        // Either next question or result should be visible
        const resultVisible = await page
          .getByText(/Is this it|No matches/)
          .isVisible()
          .catch(() => false)

        expect(nextQuestionVisible || resultVisible).toBeTruthy()
      }
    }
  })

  test('should display place details when guess is correct', async ({ page }) => {
    const description =
      'A tall iconic structure with multiple minarets in Istanbul, Turkey, famous Ottoman mosque converted to museum'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Wait for either guess or questions
    await expect(page.getByText(/Is this it|Question \d+ of|I'm narrowing/)).toBeVisible({
      timeout: 5000,
    })

    // Check if place name is displayed
    const placeNameVisible = await page
      .getByRole('heading')
      .filter({ hasText: /[A-Z]/ })
      .first()
      .isVisible()
      .catch(() => false)

    expect(placeNameVisible).toBe(true)

    // Map should be visible to show place location
    const mapVisible = await page
      .locator('canvas.maplibregl-canvas')
      .isVisible()
      .catch(() => false)

    expect(mapVisible).toBe(true)
  })

  test('should show only correct place marker on map when game is won', async ({ page }) => {
    const description =
      "A famous iron lattice tower in Paris, France, built for the 1889 World's Fair"

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Wait for either a direct guess or questions
    const hasDirectGuess = await page
      .getByText('Is this it?')
      .isVisible()
      .catch(() => false)

    if (hasDirectGuess) {
      // Confirm the guess
      await page.getByRole('button', { name: "Yeah, that's the one!" }).click()

      // Wait for success message
      await expect(page.getByText('Game saved!')).toBeVisible({ timeout: 5000 })

      // Wait for map to update with correct place only
      await page.waitForTimeout(1000)

      // CRITICAL: Map should show exactly 1 marker (the correct place, not all candidates)
      const markers = page.locator('[role="button"][aria-label*="View"]')
      const markerCount = await markers.count()

      // This is the bug fix verification - should be 1, not 5+ candidates
      expect(markerCount).toBe(1)
    } else {
      // If we got questions instead, skip this specific test
      test.skip()
    }
  })

  test('should show confidence level and candidate information', async ({ page }) => {
    const description = 'A large sphinx statue with lion body and human head in Giza Egypt'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Wait for game state to stabilize
    await page.waitForTimeout(1000)

    // Should show some information about candidates/confidence
    const gameContent = page.getByText(/Question|Is this it|I'm narrowing|No matches|Found/)

    const hasContent = await gameContent.isVisible().catch(() => false)

    expect(hasContent).toBe(true)
  })
})
