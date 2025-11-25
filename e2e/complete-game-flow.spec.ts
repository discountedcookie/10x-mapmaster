import { test, expect, handleAuth } from './fixtures'

test.describe('Complete Game Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game')
    // Handle authentication with improved logic
    await handleAuth(page)
  })

  test('should complete game with successful guess', async ({ page }) => {
    // Enter description (Eiffel Tower)
    const description =
      "A famous iron tower in Paris with a lattice structure, built for the 1889 World's Fair"
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Check character counter appears
    await expect(page.getByText(`${description.length}/200`)).toBeVisible()

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for loading overlay
    await expect(page.getByText('Reading your clues...')).toBeVisible()

    // Wait for loading to complete
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Wait for either question or result
    await page
      .waitForSelector('text=Question 1 of', { timeout: 5000 })
      .catch(() => page.waitForSelector('text=Is this it?', { timeout: 5000 }))

    // If we got a question, answer it
    if (await page.getByText('Question 1 of').isVisible()) {
      // Answer first question
      await page
        .getByRole('button', { name: 'Yes' })
        .or(page.getByRole('button', { name: 'No' }))
        .first()
        .click()

      // Wait for result
      await expect(page.getByText(/Is this it|I'm narrowing it down/)).toBeVisible({
        timeout: 10_000,
      })
    }

    // Should show a result (either high confidence guess or after questions)
    const hasGuess = await page.getByText('Is this it?').isVisible()
    const isNarrowing = await page.getByText("I'm narrowing it down").isVisible()

    expect(hasGuess || isNarrowing).toBeTruthy()

    // If there's a definitive guess, confirm it
    if (hasGuess) {
      await page.getByRole('button', { name: "Yeah, that's the one!" }).click()

      // Should show success toast
      await expect(page.getByText('Game saved!')).toBeVisible()
    }
  })

  test('should handle invalid description input', async ({ page }) => {
    // Wait for auth (use existing session or sign in)
    await page.waitForTimeout(1000)

    if (await page.getByRole('heading', { name: 'Sign In' }).isVisible()) {
      // Skip test if no existing session
      test.skip()
    }

    // Try with empty description
    await expect(page.getByRole('button', { name: "Let's Go!" })).toBeDisabled()

    // Try with too short description
    await page.getByPlaceholder(/Describe a place/).fill('short')
    await expect(page.getByText(/Description must be at least 10 characters/)).toBeVisible()
    await expect(page.getByRole('button', { name: "Let's Go!" })).toBeDisabled()

    // Valid description should enable button
    await page
      .getByPlaceholder(/Describe a place/)
      .fill('A large crater in the desert burning with natural gas')
    await expect(page.getByRole('button', { name: "Let's Go!" })).toBeEnabled()
  })

  test('should show loading state during embedding generation', async ({ page }) => {
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle')
    await page.waitForTimeout(1000)

    // Debug: check what's actually on the page
    const pageContent = await page.textContent('body')
    console.log('Page content:', pageContent?.slice(0, 500))

    if (await page.getByRole('heading', { name: 'Sign In' }).isVisible()) {
      test.skip()
    }

    // Wait for the game interface to load
    await page.waitForSelector('text=Describe a Place', { timeout: 10_000 })

    // Wait a bit more for Vue reactivity
    await page.waitForTimeout(500)

    // Enter valid description
    await page.locator('textarea').type('A famous ancient wonder with pyramids and a sphinx')

    // Verify button is enabled
    await expect(page.getByRole('button', { name: "Let's Go!" })).toBeEnabled()

    // Debug: log all buttons
    const buttons = await page.evaluate(() => {
      const btns = document.querySelectorAll('button')
      return [...btns].map((button) => ({
        text: button.textContent,
        disabled: button.disabled,
        className: button.className,
      }))
    })
    console.log('Buttons found:', buttons)

    // Click start game
    await page.getByRole('button', { name: "Let's Go!" }).click({ force: true, timeout: 5000 })

    // Should immediately disable the button (due to loading state)
    await expect(page.getByRole('button', { name: "Let's Go!" })).toBeDisabled()

    // Should show loading overlay
    await expect(page.getByText('Reading your clues...')).toBeVisible()
    await expect(page.getByText('Searching the world...')).toBeVisible()

    // Loading should eventually disappear
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })
  })

  test('should display map with candidate markers', async ({ page }) => {
    await page.waitForTimeout(1000)

    if (await page.getByRole('heading', { name: 'Sign In' }).isVisible()) {
      test.skip()
    }

    // Enter description and start game
    await page
      .getByPlaceholder(/Describe a place/)
      .fill('A tall mountain in the Himalayas, highest peak in the world')
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for game to load
    await page
      .waitForSelector('text=Question 1 of', { timeout: 15_000 })
      .catch(() => page.waitForSelector('text=Is this it?', { timeout: 1000 }))

    // Map should be visible (check for maplibre canvas)
    const mapCanvas = page.locator('canvas.maplibregl-canvas')
    await expect(mapCanvas).toBeVisible()

    // Markers should have ARIA labels (check for marker elements)
    const markers = page.locator('[role="button"][aria-label*="View"]')
    const markerCount = await markers.count()
    expect(markerCount).toBeGreaterThan(0)
  })
})
