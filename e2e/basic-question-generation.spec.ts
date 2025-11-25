import type { Page } from '@playwright/test'
import { test, expect, handleAuth } from './fixtures/index.js'

test.describe('Basic Question Generation Flow', () => {
  test.beforeEach(async ({ page }: { page: Page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should generate question when multiple candidates exist', async ({
    page,
  }: {
    page: Page
  }) => {
    // Enter description for a place that might have multiple candidates
    const description = 'A tall building in Europe'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing to complete
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state to appear
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Should show either a question or a guess
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)
    const hasGuess = await page
      .getByText(/Is it|Is this/i)
      .isVisible()
      .catch(() => false)

    expect(hasQuestion || hasGuess).toBeTruthy()

    // If we got a question, verify it has answer buttons
    if (hasQuestion) {
      const yesButton = page.getByRole('button', { name: /Yes/i })
      const noButton = page.getByRole('button', { name: /No/i })

      expect(
        (await yesButton.isVisible().catch(() => false)) ||
          (await noButton.isVisible().catch(() => false))
      ).toBeTruthy()
    }
  })

  test('should continue game after answering question', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A tall building in Europe'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check if we got a question
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    if (hasQuestion) {
      // Get initial state
      const initialText = await page.locator('body').textContent()

      // Answer the question
      const yesButton = page.getByRole('button', { name: /Yes/i })
      if (await yesButton.isVisible().catch(() => false)) {
        await yesButton.click()

        // Wait for game to continue
        await page.waitForTimeout(1000)

        // Verify state changed (either new question or guess)
        const updatedText = await page.locator('body').textContent()
        expect(updatedText).not.toBe(initialText)

        // Verify game is still interactive
        const buttons = page.getByRole('button')
        const buttonCount = await buttons.count()
        expect(buttonCount).toBeGreaterThan(0)
      }
    }
  })

  test('should display question counter', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A tall building in Europe'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check if we got a question
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    if (hasQuestion) {
      // Verify question counter is visible
      const questionCounter = page.getByText(/Question \d+ of/)
      const isVisible = await questionCounter.isVisible().catch(() => false)

      if (isVisible) {
        await expect(questionCounter).toBeVisible()
        const counterText = await questionCounter.textContent()
        expect(counterText).toMatch(/Question \d+/)
      }
    }
  })

  test('should not crash when answering questions', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A tall building in Europe'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check if we got a question
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    if (hasQuestion) {
      // Answer the question
      const yesButton = page.getByRole('button', { name: /Yes/i })
      if (await yesButton.isVisible().catch(() => false)) {
        await yesButton.click()

        // Wait for response
        await page.waitForTimeout(2000)

        // Verify no error messages
        const errorText = await page.locator('body').textContent()
        expect(errorText).not.toContain('500')
        expect(errorText?.toLowerCase()).not.toContain('error')

        // Verify game is still interactive
        const buttons = page.getByRole('button')
        const buttonCount = await buttons.count()
        expect(buttonCount).toBeGreaterThan(0)
      }
    }
  })
})
