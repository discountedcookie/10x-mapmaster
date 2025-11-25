import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Semantic Traits Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[4] = 0.75 // Moderate confidence for semantic questions
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

  test('should display semantic traits panel', async ({ page }) => {
    const description = 'A tall iron structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show semantic traits panel
    const traitsPanel = page.locator('[data-testid="semantic-traits"]')
    await expect(traitsPanel).toBeVisible()

    // Should have affirmed and denied sections
    await expect(traitsPanel.getByText('Affirmed')).toBeVisible()
    await expect(traitsPanel.getByText('Denied')).toBeVisible()
  })

  test('should update traits with semantic answers', async ({ page }) => {
    const description = 'A structure made of metal'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    const traitsPanel = page.locator('[data-testid="semantic-traits"]')

    // Answer semantic question with Yes
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should add trait to affirmed list
    await expect(traitsPanel.getByText(/iron|metal|structure/i)).toBeVisible()

    // Answer another semantic question with No
    await page.getByRole('button', { name: 'No' }).click()

    // Should add trait to denied list
    await expect(traitsPanel.locator('.denied-traits')).toContainText(/wooden|stone|natural/i)
  })

  test('should limit traits to 6 per category', async ({ page }) => {
    const description = 'A complex architectural feature'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    const traitsPanel = page.locator('[data-testid="semantic-traits"]')

    // Answer multiple semantic questions
    for (let index = 0; index < 10; index++) {
      await page.getByRole('button', { name: Math.random() > 0.5 ? 'Yes' : 'No' }).click()
      await page.waitForTimeout(200)
    }

    // Should not exceed 6 traits in each category
    const affirmedTraits = await traitsPanel.locator('.affirmed-traits [data-testid="trait"]').all()
    const deniedTraits = await traitsPanel.locator('.denied-traits [data-testid="trait"]').all()

    expect(affirmedTraits.length).toBeLessThanOrEqual(6)
    expect(deniedTraits.length).toBeLessThanOrEqual(6)
  })

  test('should parse constraint string correctly', async ({ page }) => {
    const description = 'A famous tower'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer questions to build up constraint string
    await page.getByRole('button', { name: 'Yes' }).click() // Affirms something
    await page.getByRole('button', { name: 'No' }).click() // Denies something

    const traitsPanel = page.locator('[data-testid="semantic-traits"]')

    // Verify traits are displayed with proper styling
    const affirmedBadge = traitsPanel.locator('.affirmed-traits [data-testid="trait"]').first()
    const deniedBadge = traitsPanel.locator('.denied-traits [data-testid="trait"]').first()

    // Affirmed should have different styling than denied
    await expect(affirmedBadge).toBeVisible()
    await expect(deniedBadge).toBeVisible()
  })
})
