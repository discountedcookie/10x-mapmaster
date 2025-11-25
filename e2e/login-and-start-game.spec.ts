import { test, expect } from './fixtures'

test.describe('Login and Start Game Flow', () => {
  test('should login with test credentials and start a game', async ({ page }) => {
    // Navigate to login page
    await page.goto('/login')

    // Wait for login form to load
    await page.waitForSelector('form')

    // Enter test credentials
    await page.getByPlaceholder('you@example.com').fill('user1@example.com')
    await page.getByPlaceholder('••••••••').fill('password123')

    // Click login button
    await page.getByRole('button', { name: 'Log In' }).click()

    // Wait for redirect to game page
    await page.waitForURL('**/game')

    // Verify we're on the game page
    expect(page.url()).toContain('/game')

    // Enter place description
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Click "Let's Go!" button
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Verify loading state appears
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for loading to complete (or timeout - services may not be available in test)
    await expect(page.getByText('Reading your clues...')).not.toBeVisible({ timeout: 15_000 })

    // Verify the game start process was initiated (left the start screen)
    const stillOnStart = await page.getByText('Describe a Place').isVisible()
    expect(stillOnStart).toBe(false)

    // The test successfully demonstrated the login -> game start flow
    // Note: Full game progression may require additional service mocking
  })
})
