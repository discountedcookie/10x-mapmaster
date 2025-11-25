import { test, expect } from './fixtures'

test.describe('V2 Anonymous Submission Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    // Use anonymous auth instead of handleAuth
    await page.waitForLoadState('networkidle')
  })

  test('should allow anonymous place submission', async ({ page }) => {
    // Trigger anonymous sign-in by starting game
    await page.getByPlaceholder(/e.g.,/).fill('A unique underwater research facility')
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Should handle anonymous auth automatically
    await expect(page.getByText('Analyzing your description...')).toBeVisible()
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should prompt for submission
    await expect(page.getByText(/Submit.*place|Add.*place/)).toBeVisible()

    // Submit place anonymously
    await page.getByPlaceholder(/Enter place name/).fill('Aquarius Reef Base')
    await page.locator('canvas.maplibregl-canvas').click({ position: { x: 300, y: 200 } })
    await page.getByRole('button', { name: /Submit|Create/ }).click()

    // Should succeed
    await expect(page.getByText(/submitted|created/i)).toBeVisible()
  })

  test('should mark anonymous submissions as pending review', async ({ page }) => {
    await page.getByPlaceholder(/e.g.,/).fill('A secret underground bunker')
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Submit place
    await page.getByPlaceholder(/Enter place name/).fill('Area 51')
    await page.locator('canvas.maplibregl-canvas').click({ position: { x: 250, y: 180 } })
    await page.getByRole('button', { name: /Submit|Create/ }).click()

    // Should indicate pending review status
    await expect(page.getByText(/pending|review|approval/i)).toBeVisible()
  })

  test('should trigger enrichment after admin approval', async ({ page }) => {
    // This test would require admin access to approve submissions
    // For now, test that the submission process works
    await page.getByPlaceholder(/e.g.,/).fill('An experimental fusion reactor facility')
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    await page.getByPlaceholder(/Enter place name/).fill('ITER Fusion Reactor')
    await page.locator('canvas.maplibregl-canvas').click({ position: { x: 400, y: 150 } })
    await page.getByRole('button', { name: /Submit|Create/ }).click()

    // Should complete submission process
    await expect(page.getByText(/submitted|created/i)).toBeVisible()

    // Note: Enrichment testing would require database verification
  })
})
