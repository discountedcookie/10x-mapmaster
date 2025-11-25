import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Mobile Responsiveness Test', () => {
  test.use({ viewport: { width: 375, height: 667 } }) // iPhone SE size

  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should work on mobile viewport', async ({ page }) => {
    // Enter description
    const description = 'A famous tower'
    await page.getByPlaceholder(/e.g.,/).fill(description)

    // Start game
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should work on mobile
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show mobile-optimized layout
    await expect(page.locator('[data-testid="chat-container"]')).toBeVisible()
    await expect(page.locator('canvas.maplibregl-canvas')).toBeVisible()
  })

  test('should have touch-friendly buttons', async ({ page }) => {
    const description = 'A landmark'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer buttons should be appropriately sized for touch
    const yesButton = page.getByRole('button', { name: 'Yes' })
    const noButton = page.getByRole('button', { name: 'No' })

    await expect(yesButton).toBeVisible()
    await expect(noButton).toBeVisible()

    // Check button sizes are adequate for touch (minimum 44px)
    const yesBox = await yesButton.boundingBox()
    const noBox = await noButton.boundingBox()

    expect(yesBox?.height).toBeGreaterThanOrEqual(44)
    expect(noBox?.height).toBeGreaterThanOrEqual(44)
  })

  test('should handle map on mobile', async ({ page }) => {
    const description = 'A statue'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Map should be visible and usable on mobile
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible()

    // Map should fit mobile viewport
    const mapBox = await mapCanvas.boundingBox()
    expect(mapBox?.width).toBeLessThanOrEqual(375)
  })

  test('should scroll chat properly on mobile', async ({ page }) => {
    const description = 'A building'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer multiple questions to build chat history
    for (let index = 0; index < 5; index++) {
      await page.getByRole('button', { name: 'Yes' }).click()
      await page.waitForTimeout(500)
    }

    // Chat should be scrollable on mobile
    const chatContainer = page.locator('[data-testid="chat-container"]')
    await expect(chatContainer).toBeVisible()

    // Should be able to scroll
    await chatContainer.evaluate((element) => element.scrollTo(0, element.scrollHeight))
  })
})
