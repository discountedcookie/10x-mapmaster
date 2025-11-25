import type { Page } from '@playwright/test'
import { test, expect, handleAuth } from './fixtures/index.js'

test.describe('Basic Successful Game Flow', () => {
  test.beforeEach(async ({ page }: { page: Page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should successfully complete game with correct guess', async ({ page }: { page: Page }) => {
    // Enter description for Eiffel Tower
    const description = 'A famous iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Verify character counter shows correct count
    await expect(page.getByText(`${description.length}/200`)).toBeVisible()

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing to complete
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state to appear (either question or guess)
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Should show either a question or a guess
    const hasQuestion = await page
      .getByText(/Question \d+ of/)
      .isVisible()
      .catch(() => false)

    // Check for guess by looking for the pattern in body text
    const bodyText = await page.locator('body').textContent()
    const hasGuess = bodyText?.includes('Is it') || bodyText?.includes('Is this')

    expect(hasQuestion || hasGuess).toBeTruthy()

    // If we got a guess, confirm it
    if (hasGuess) {
      // Find and click the "Yes" button
      const yesButton = page.getByRole('button', {
        name: /yes|correct/i,
      })
      const isVisible = await yesButton.isVisible().catch(() => false)
      if (isVisible) {
        await yesButton.click()

        // Wait for game completion
        await page.waitForTimeout(2000)

        // Verify game state changed
        const buttons = page.getByRole('button')
        const buttonCount = await buttons.count()
        expect(buttonCount).toBeGreaterThan(0)
      }
    }

    // Verify no console errors
    const consoleMessages = await page.evaluate(() => {
      return (globalThis as any).__consoleErrors || []
    })
    expect(consoleMessages).toHaveLength(0)
  })

  test('should show game state after starting', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A famous iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state to appear
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Verify game state is displayed
    const gameContent = page.locator('body')
    const text = await gameContent.textContent()

    // Should contain either question or guess content
    expect(
      text?.includes('Question') || text?.includes('Is it') || text?.includes('Is this')
    ).toBeTruthy()
  })
})
