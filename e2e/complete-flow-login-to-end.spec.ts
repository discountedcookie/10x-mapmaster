import { test, expect, handleAuth } from './fixtures'
import type { Page } from '@playwright/test'

/**
 * Comprehensive E2E test for complete game flow from login to end screen.
 * Tests the entire user journey including:
 * - Clean browser state (auth setup)
 * - Login/authentication
 * - Game initialization
 * - Question answering
 * - Guess mechanics
 * - End screen verification
 */
test.describe('Complete Game Flow: Login to End Screen', () => {
  test('should complete full game flow from login to end screen with successful guess', async ({
    page,
  }: {
    page: Page
  }) => {
    // Step 1: Navigate to home page (clean state)
    console.log('Step 1: Navigating to home page...')
    await page.goto('/')

    // Step 2: Verify we're on home page and can navigate to game
    console.log('Step 2: Verifying home page...')
    await expect(page.getByRole('heading')).toBeVisible({ timeout: 5000 })

    // Step 3: Navigate to game page
    console.log('Step 3: Navigating to game page...')
    await page.goto('/game')

    // Step 4: Handle authentication (fixture sets up mock auth token)
    console.log('Step 4: Handling authentication...')
    await handleAuth(page)

    // Step 5: Verify game page loaded with description input
    console.log('Step 5: Verifying game page loaded...')
    const descriptionInput = page.getByPlaceholder(/Describe a place/)
    await expect(descriptionInput).toBeVisible({ timeout: 5000 })

    // Step 6: Enter a distinctive place description
    console.log('Step 6: Entering place description...')
    const description =
      "A famous iron lattice tower in Paris, France, built in 1889 for the World's Fair, iconic landmark with elevators"

    await descriptionInput.fill(description)

    // Verify description was entered
    await expect(page.getByText(`${description.length}/200`)).toBeVisible()

    // Step 7: Start the game
    console.log('Step 7: Starting game...')
    const startButton = page.getByRole('button', { name: "Let's Go!" })
    await expect(startButton).toBeEnabled()
    await startButton.click()

    // Step 8: Wait for loading to complete
    console.log('Step 8: Waiting for game initialization...')
    await expect(page.getByText('Reading your clues...')).toBeVisible({
      timeout: 5000,
    })

    // Wait for loading to finish
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Step 9: Verify game interface loaded
    console.log('Step 9: Verifying game interface...')
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible({ timeout: 5000 })

    // Step 10: Handle game flow - answer questions or make guess
    console.log('Step 10: Playing game...')

    let turnCount = 0
    const maxTurns = 10 // Prevent infinite loops

    while (turnCount < maxTurns) {
      turnCount++
      console.log(`Turn ${turnCount}...`)

      // Check if we have a question
      const questionVisible = await page
        .getByText(/Question \d+ of \d+/)
        .isVisible()
        .catch(() => false)

      // Check if we have a guess
      const guessVisible = await page
        .getByText('Is this it?')
        .isVisible()
        .catch(() => false)

      // Check if game is complete
      const completeVisible = await page
        .getByText(/Game saved|You found it|Success|Complete|Correct/)
        .isVisible()
        .catch(() => false)

      if (completeVisible) {
        console.log('Game completed!')
        break
      }

      if (questionVisible) {
        console.log(`Answering question ${turnCount}...`)

        // Answer the question with "Yes"
        const yesButton = page.getByRole('button', { name: 'Yes' }).first()

        if (await yesButton.isVisible()) {
          await yesButton.click()

          // Wait for next state
          await page.waitForTimeout(500)
        } else {
          console.log('No Yes button found, breaking')
          break
        }
      } else if (guessVisible) {
        console.log('Making guess...')

        // Confirm the guess
        const confirmButton = page.getByRole('button', {
          name: "Yeah, that's the one!",
        })

        if (await confirmButton.isVisible()) {
          await confirmButton.click()

          // Wait for completion
          await page.waitForTimeout(500)
        } else {
          console.log('No confirmation button found')
          break
        }
      } else {
        console.log('No question or guess visible, waiting...')
        await page.waitForTimeout(500)

        // Check again
        const stillLoading = await page
          .getByText(/Reading|Analyzing|Searching/)
          .isVisible()
          .catch(() => false)

        if (stillLoading) {
          console.log('Still loading, waiting...')
          await page.waitForTimeout(1000)
        } else {
          console.log('Unknown state, breaking')
          break
        }
      }
    }

    // Step 11: Verify end screen
    console.log('Step 11: Verifying end screen...')

    // Should show game completion message
    await expect(page.getByText(/Game saved|You found it|Success|Complete|Correct/)).toBeVisible({
      timeout: 5000,
    })

    // Should have a way to play again or return home
    const playAgainButton = page.getByRole('button', { name: /Play Again|New Game|Home/ }).first()

    const hasPlayAgain = await playAgainButton.isVisible().catch(() => false)
    expect(hasPlayAgain).toBe(true)

    console.log('✓ Complete game flow test passed!')
  })

  test('should handle game flow with multiple question answers', async ({
    page,
  }: {
    page: Page
  }) => {
    // Navigate and authenticate
    await page.goto('/game')
    await handleAuth(page)

    // Enter description
    const description =
      'A massive stone structure with four giant carved faces of presidents on a mountain in South Dakota'

    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for loading
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer multiple questions
    let questionsAnswered = 0
    const maxQuestions = 5

    while (questionsAnswered < maxQuestions) {
      const questionVisible = await page
        .getByText(/Question \d+ of \d+/)
        .isVisible()
        .catch(() => false)

      const guessVisible = await page
        .getByText('Is this it?')
        .isVisible()
        .catch(() => false)

      const completeVisible = await page
        .getByText(/Game saved|You found it/)
        .isVisible()
        .catch(() => false)

      if (completeVisible) {
        console.log('Game completed after answering questions')
        break
      }

      if (questionVisible) {
        // Answer with "Yes"
        await page.getByRole('button', { name: 'Yes' }).first().click()
        questionsAnswered++
        await page.waitForTimeout(500)
      } else if (guessVisible) {
        // Confirm guess
        await page.getByRole('button', { name: "Yeah, that's the one!" }).click()
        break
      } else {
        break
      }
    }

    // Verify completion
    await expect(page.getByText(/Game saved|You found it|Success/)).toBeVisible({ timeout: 5000 })

    console.log(`✓ Answered ${questionsAnswered} questions and completed game`)
  })

  test('should display map and candidate information during gameplay', async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)

    // Start a game
    const description = 'A tall structure in New York City with observation decks'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for game to load
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Verify map is visible
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible({ timeout: 5000 })

    // Verify game content is visible (question or guess)
    const gameContent = await page
      .getByText(/Question|Is this it/)
      .isVisible()
      .catch(() => false)

    expect(gameContent).toBe(true)

    console.log('✓ Map and game interface verified')
  })

  test('should maintain game state across interactions', async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)

    // Start game
    const description = 'A famous ancient monument with a sphinx and pyramids'

    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for game to load
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Get initial state
    const initialContent = await page.textContent('body')

    // Answer a question if available
    const yesButton = page.getByRole('button', { name: 'Yes' }).first()
    if (await yesButton.isVisible()) {
      await yesButton.click()
      await page.waitForTimeout(500)

      // Verify state changed
      const newContent = await page.textContent('body')
      expect(newContent).not.toBe(initialContent)

      console.log('✓ Game state updated after answer')
    }

    // Verify map is still visible
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible()

    console.log('✓ Game state maintained across interactions')
  })
})
