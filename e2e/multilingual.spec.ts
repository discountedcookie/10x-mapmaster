import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Multilingual Test', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    await handleAuth(page)
  })

  test('should support Spanish language interface', async ({ page }) => {
    // Change language to Spanish
    await page.getByRole('button', { name: /language|idioma/i }).click()
    await page.getByText('Español').click()

    // Should show Spanish text
    await expect(page.getByText('Describe un lugar')).toBeVisible()
    await expect(page.getByPlaceholder(/ejemplo|descripción/i)).toBeVisible()
  })

  test('should process Spanish descriptions correctly', async ({ page }) => {
    // Set language to Spanish
    await page.getByRole('button', { name: /language|idioma/i }).click()
    await page.getByText('Español').click()

    // Enter Spanish description
    const description =
      'Una famosa torre de hierro en París construida para la Exposición Universal de 1889'
    await page.getByPlaceholder(/ejemplo|descripción/i).fill(description)
    await page.getByRole('button', { name: 'Iniciar juego' }).click()

    // Should process and show questions in English (canonical)
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })
    await expect(page.getByText(/Question|Is this/i)).toBeVisible()
  })

  test('should handle non-English input for enrichment', async ({ page }) => {
    // Set language to French
    await page.getByRole('button', { name: /language|idioma/i }).click()
    await page.getByText('Français').click()

    // Enter French description
    const description = 'Une célèbre tour Eiffel à Paris'
    await page.getByPlaceholder(/exemple|description/i).fill(description)
    await page.getByRole('button', { name: 'Démarrer' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should work with French input
    await expect(page.getByText(/Question|Is this/i)).toBeVisible()
  })
})
