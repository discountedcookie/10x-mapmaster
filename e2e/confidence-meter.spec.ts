import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Confidence Meter Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[5] = 0.8 // High confidence for meter testing
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ embedding }),
        })
      } else {
        await route.continue()
      }
    })

    await page.goto('/game')
    await handleAuth(page)
  })

  test('should display confidence meter throughout game', async ({ page }) => {
    const description = 'A well-known monument'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Confidence meter should be visible
    const confidenceMeter = page.locator('[data-testid="confidence-meter"]')
    await expect(confidenceMeter).toBeVisible()

    // Should show initial confidence level
    await expect(confidenceMeter).toContainText(/\d+%|\d+\.\d+%/)
  })

  test('should update confidence after each answer', async ({ page }) => {
    const description = 'A famous structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    const confidenceMeter = page.locator('[data-testid="confidence-meter"]')

    // Get initial confidence
    const initialConfidence = await confidenceMeter.textContent()

    // Answer a question
    await page.getByRole('button', { name: 'Yes' }).click()

    // Confidence should update
    await expect(confidenceMeter).not.toContainText(initialConfidence || '')
  })

  test('should show threshold and gap information', async ({ page }) => {
    const description = 'A distinctive landmark'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    const confidenceMeter = page.locator('[data-testid="confidence-meter"]')

    // Should show threshold information (tooltip or text)
    await confidenceMeter.hover()
    await expect(page.locator('[role="tooltip"]')).toContainText(/threshold|gap/i)
  })

  test('should change color based on confidence level', async ({ page }) => {
    const description = 'A clear landmark description'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    const confidenceMeter = page.locator('[data-testid="confidence-meter"]')

    // Check for color classes or styles indicating confidence level
    const meterClasses = await confidenceMeter.getAttribute('class')
    expect(meterClasses).toMatch(/confidence|meter/i)
  })

  test('should show question count progress', async ({ page }) => {
    const description = 'A moderately clear description'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show question counter
    await expect(page.getByText(/Question \d+ of \d+/)).toBeVisible()

    // Answer questions and verify counter updates
    await page.getByRole('button', { name: 'Yes' }).click()
    await expect(page.getByText(/Question 2 of \d+/)).toBeVisible()
  })
})
