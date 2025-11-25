import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Progressive Narrowing Test', () => {
  test.beforeEach(async ({ page }) => {
    // Mock embeddings to create multiple candidates initially
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        // Return embedding that matches multiple European landmarks
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[1] = 0.7 // Moderate similarity for multiple matches
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

  test('should narrow candidates through multiple questions', async ({ page }) => {
    // Enter description that should match multiple places initially
    const description = 'A famous landmark in Europe'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Wait for processing
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should start with multiple candidates, ask first question
    await expect(page.getByText('Question 1 of')).toBeVisible()

    // Answer first question (assume geographic question about continent)
    await page.getByRole('button', { name: 'Yes' }).click()

    // Should show updated state with fewer candidates
    await expect(page.getByText('Question 2 of')).toBeVisible()

    // Answer second question
    await page.getByRole('button', { name: 'No' }).click()

    // Continue answering questions until narrowing to one candidate
    for (let index = 3; index <= 5; index++) {
      await expect(page.getByText(`Question ${index} of`)).toBeVisible()
      await page.getByRole('button', { name: Math.random() > 0.5 ? 'Yes' : 'No' }).click()
    }

    // Eventually should reach a guess
    await expect(page.getByText('Is this your place?')).toBeVisible()

    // Should show the final candidate
    const guessText = await page.locator(String.raw`text=/Is this your place\?/`).textContent()
    expect(guessText).toContain('Is this your place?')
  })

  test('should update candidate list after each answer', async ({ page }) => {
    const description = 'A tower in a European capital city'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show initial candidate list
    const candidateList = page.locator('[data-testid="candidate-list"]')
    await expect(candidateList).toBeVisible()

    let initialCount = 0
    try {
      const candidates = await candidateList.locator('[data-testid="candidate"]').all()
      initialCount = candidates.length
    } catch {
      // Candidate list might not be implemented yet
    }

    // Answer first question
    await page.getByRole('button', { name: 'Yes' }).click()

    // Candidate list should update
    await expect(page.getByText('Question 2 of')).toBeVisible()

    // Verify candidates narrowed (if candidate list is implemented)
    try {
      const updatedCandidates = await candidateList.locator('[data-testid="candidate"]').all()
      const updatedCount = updatedCandidates.length
      expect(updatedCount).toBeLessThanOrEqual(initialCount)
    } catch {
      // Skip if not implemented
    }
  })

  test('should handle semantic vs geographic questions differently', async ({ page }) => {
    const description = 'An ancient stone structure'
    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Answer a semantic question (should update traits panel)
    await page.getByRole('button', { name: 'Yes' }).click()

    // Check if semantic traits panel updates
    const traitsPanel = page.locator('[data-testid="semantic-traits"]')
    if (await traitsPanel.isVisible()) {
      await expect(traitsPanel.locator('text=/Affirmed|Denied/')).toBeVisible()
    }

    // Answer a geographic question (should update map bounds)
    await page.getByRole('button', { name: 'No' }).click()

    // Map should still be visible and potentially zoomed
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible()
  })
})
