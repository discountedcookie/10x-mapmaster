import { test, expect, handleAuth } from './fixtures'

test.describe('Game Flow: Unsuccessful Guess and Retry', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to game page
    await page.goto('/game')

    // Handle authentication with improved logic
    await handleAuth(page)
  })

  test('should handle case where initial guess is wrong', async ({ page }) => {
    // Use a description that might have multiple candidates
    // Answer in a way that might lead to wrong guess
    const description = 'A famous landmark in Europe'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for analysis to complete
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    // Wait for game state
    await page.waitForTimeout(500)

    // Check if we got a guess
    const hasGuess = await page
      .getByText('Is this it?')
      .isVisible()
      .catch(() => false)

    const hasQuestions = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    expect(hasGuess || hasQuestions).toBe(true)

    // If there's a "No, that's not it" button, test the rejection flow
    const noButton = page.getByRole('button', { name: /No|That's not it/i })

    if (await noButton.isVisible()) {
      await noButton.click()

      // After rejection, game should either:
      // 1. Ask more questions to narrow down
      // 2. Ask to submit the correct place
      await page.waitForTimeout(500)

      const moreOptionsAvailable =
        (await page
          .getByText(/Question|submit|correct place/i)
          .isVisible()
          .catch(() => false)) ||
        (await page
          .getByText(/I'm still learning|help me learn/i)
          .isVisible()
          .catch(() => false))

      expect(moreOptionsAvailable).toBe(true)
    }
  })

  test('should allow retry after unsuccessful guess', async ({ page }) => {
    const description = 'A structure with towers and walls'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    await page.waitForTimeout(500)

    // Look for retry or "New Game" button
    const newGameButton = page.getByRole('button', { name: /New Game|Retry|Try Again/i })

    const gameExists = await page
      .getByText(/Question|Is this it|No matches/)
      .isVisible()
      .catch(() => false)

    expect(gameExists).toBe(true)

    // If retry/new game button exists, verify it works
    if (await newGameButton.isVisible()) {
      await newGameButton.click()

      // Should return to game start screen
      await expect(page.getByText('Describe a Place')).toBeVisible({ timeout: 5000 })
    }
  })

  test('should show "No matches found" when description is too obscure', async ({ page }) => {
    // Use an extremely specific or made-up description
    const verySpecificDescription =
      'A purple pyramid shaped building with exactly 7 windows in a fictional desert city'

    await page.getByPlaceholder(/e.g.,/).fill(verySpecificDescription)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for analysis
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    await page.waitForTimeout(500)

    // Should either:
    // 1. Show "No matches found"
    // 2. Ask questions to try to find something
    // 3. Show low confidence result

    const noMatches = await page
      .getByText(/No matches|not found|nothing found/i)
      .isVisible()
      .catch(() => false)

    const hasQuestions = await page
      .getByText(/Question/)
      .isVisible()
      .catch(() => false)

    const hasResult = await page
      .getByText(/Is this it|I'm narrowing/)
      .isVisible()
      .catch(() => false)

    expect(noMatches || hasQuestions || hasResult).toBe(true)
  })

  test('should handle rejection with option to provide more details', async ({ page }) => {
    const description = 'A large building'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    await page.waitForTimeout(500)

    // Wait for either questions or guess
    await expect(page.getByText(/Question|Is this it|I'm narrowing|No matches/)).toBeVisible()

    // If there's a "No" or rejection button, click it
    const rejectButton = page.getByRole('button', { name: /No|That's not|incorrect/i })

    if (await rejectButton.isVisible()) {
      await rejectButton.click()

      // Should show options to continue (ask more questions, provide feedback, etc.)
      await page.waitForTimeout(500)

      const hasContinueOption = await page
        .getByText(/Question|submit|help me|tell me more/i)
        .isVisible()
        .catch(() => false)

      expect(hasContinueOption).toBe(true)
    }
  })

  test('should track game state properly on unsuccessful guess', async ({ page }) => {
    const description = 'A bridge over water'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    await page.waitForTimeout(500)

    // Verify game is in active state (showing content)
    const gameActive = await page
      .getByText(/Question|Is this it|I'm narrowing|No matches/)
      .isVisible()

    expect(gameActive).toBe(true)

    // UI should show question counter or confidence indicator if applicable
    const questionCounter = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    const resultDisplay = await page
      .getByText(/Is this it/)
      .isVisible()
      .catch(() => false)

    expect(questionCounter || resultDisplay).toBe(true)
  })

  test('should allow user to provide feedback or correction', async ({ page }) => {
    const description = 'A tall structure'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 10_000,
    })

    await page.waitForTimeout(500)

    // Look for any feedback or "tell me what it is" button
    const feedbackButton = page.getByRole('button', {
      name: /tell me|what is|skip|submit|feedback/i,
    })

    const hasGameContent = await page.getByText(/Question|Is this|I'm narrowing/).isVisible()

    expect(hasGameContent).toBe(true)

    // If feedback button exists, it should be accessible
    if (await feedbackButton.isVisible()) {
      expect(await feedbackButton.isEnabled()).toBe(true)
    }
  })
})
