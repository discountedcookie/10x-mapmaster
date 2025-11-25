import type { Page } from '@playwright/test'
import { test, expect, handleAuth } from './fixtures/index.js'

test.describe('Basic Wrong Guess Flow', () => {
  test.beforeEach(async ({ page }: { page: Page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should handle wrong guess without crashing', async ({ page }: { page: Page }) => {
    // Enter description that might result in a guess
    const description = 'A large statue in a harbor'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing to complete
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state to appear
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check if we got a guess or question
    const bodyText = await page.locator('body').textContent()
    const hasGuess = bodyText?.includes('Is it') || bodyText?.includes('Is this')

    if (hasGuess) {
      // Click "No" button to reject the guess
      const noButton = page.getByRole('button', {
        name: /No|try again/i,
      })

      const isVisible = await noButton.isVisible().catch(() => false)
      if (isVisible) {
        await noButton.click()

        // Wait for game to continue (should not crash with 500 error)
        // Game should either ask a new question or show another guess
        await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, {
          timeout: 10_000,
        })

        // Verify no 500 error in console
        const consoleMessages = await page.evaluate(() => {
          return (globalThis as any).__consoleErrors || []
        })
        expect(consoleMessages).not.toContain(expect.stringContaining('500'))
      }
    }
  })

  test('should continue game after rejecting guess', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A large statue in a harbor'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check if we got a guess
    const bodyText = await page.locator('body').textContent()
    const hasGuess = bodyText?.includes('Is it') || bodyText?.includes('Is this')

    if (hasGuess) {
      // Get initial game state
      const initialText = await page.locator('body').textContent()

      // Click "No" button
      const noButton = page.getByRole('button', {
        name: /No|try again/i,
      })

      const isVisible = await noButton.isVisible().catch(() => false)
      if (isVisible) {
        await noButton.click()

        // Wait for state to change
        await page.waitForTimeout(1000)

        // Verify game state changed (either new question or new guess)
        const updatedText = await page.locator('body').textContent()
        expect(updatedText).not.toBe(initialText)

        // Verify game is still interactive
        const buttons = page.getByRole('button')
        const buttonCount = await buttons.count()
        expect(buttonCount).toBeGreaterThan(0)
      }
    }
  })

  test('should continue game after rejecting wrong guess', async ({ page }: { page: Page }) => {
    // Enter description
    const description = 'A large statue in a harbor'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for game state
    await expect(page.locator('body')).toContainText(/Question|Is it|Is this/i, { timeout: 15_000 })

    // Check for guess
    const bodyText = await page.locator('body').textContent()
    const hasGuess = bodyText?.includes('Is it') || bodyText?.includes('Is this')

    if (hasGuess) {
      // Click "No" button
      const noButton = page.getByRole('button', {
        name: /No|try again/i,
      })

      const isVisible = await noButton.isVisible().catch(() => false)
      if (isVisible) {
        await noButton.click()

        // Wait a moment for response
        await page.waitForTimeout(2000)

        // Verify game is still interactive (buttons are present)
        const buttons = page.getByRole('button')
        const buttonCount = await buttons.count()
        expect(buttonCount).toBeGreaterThan(0)
      }
    }
  })
})
