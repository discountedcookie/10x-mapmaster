import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Concurrent Sessions Test', () => {
  test('should handle multiple users playing simultaneously', async ({ browser }) => {
    // Create multiple browser contexts for concurrent users
    const context1 = await browser.newContext()
    const context2 = await browser.newContext()

    const page1 = await context1.newPage()
    const page2 = await context2.newPage()

    // User 1 starts game
    await page1.goto('/game')
    await handleAuth(page1)
    await page1.getByPlaceholder(/e.g.,/).fill('A famous tower')
    await page1.getByRole('button', { name: 'Start Game' }).click()

    // User 2 starts game simultaneously
    await page2.goto('/game')
    await handleAuth(page2)
    await page2.getByPlaceholder(/e.g.,/).fill('A large statue')
    await page2.getByRole('button', { name: 'Start Game' }).click()

    // Both should proceed independently
    await expect(page1.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })
    await expect(page2.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Both should have their own sessions
    await expect(page1.getByText(/Question|Is this/)).toBeVisible()
    await expect(page2.getByText(/Question|Is this/)).toBeVisible()

    // Clean up
    await context1.close()
    await context2.close()
  })

  test('should isolate session data between users', async ({ browser }) => {
    const context1 = await browser.newContext()
    const context2 = await browser.newContext()

    const page1 = await context1.newPage()
    const page2 = await context2.newPage()

    // Both users start games
    await page1.goto('/game')
    await handleAuth(page1)
    await page1.getByPlaceholder(/e.g.,/).fill('Eiffel Tower')
    await page1.getByRole('button', { name: 'Start Game' }).click()

    await page2.goto('/game')
    await handleAuth(page2)
    await page2.getByPlaceholder(/e.g.,/).fill('Statue of Liberty')
    await page2.getByRole('button', { name: 'Start Game' }).click()

    await expect(page1.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })
    await expect(page2.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Each should see different content based on their description
    const page1Content = await page1.textContent('body')
    const page2Content = await page2.textContent('body')

    // Content should be different (different questions/candidates)
    expect(page1Content).not.toEqual(page2Content)

    await context1.close()
    await context2.close()
  })
})
