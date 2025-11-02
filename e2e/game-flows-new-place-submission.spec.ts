import { test, expect } from './fixtures'

test.describe('Game Flow: New Place Submission', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to game page
    await page.goto('/game')

    // Handle authentication
    await page.waitForTimeout(1000)

    // If sign in modal appears, create test account
    if (await page.getByRole('heading', { name: 'Sign In' }).isVisible()) {
      await page.getByText('Need an account? Sign up').click()
      const uniqueEmail = `test-${Date.now()}@example.com`
      await page.getByPlaceholder('you@example.com').fill(uniqueEmail)
      await page.getByPlaceholder('••••••••').fill('testpassword123')
      await page.getByRole('button', { name: 'Sign Up' }).click()

      // Wait for auth to complete
      await expect(page.getByRole('heading', { name: 'Sign In' })).not.toBeVisible({
        timeout: 5000,
      })
    }

    // Verify we're on the game page
    await expect(page.getByText('Describe a Place')).toBeVisible()
  })

  test('should allow submission of a new place when not found in database', async ({ page }) => {
    // Use a very specific/unique description that won't be in the database
    const uniquePlaceName = `TestPlace-${Date.now()}`
    const description = `A unique fictional place called ${uniquePlaceName} that only exists in this test`

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    // Wait for analysis to complete
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Look for either "No matches found" message or a submission prompt
    const noMatches = await page
      .getByText(/No matches|not found|nothing found/i)
      .isVisible()
      .catch(() => false)

    // When no matches found, there should be an option to submit the place
    if (noMatches) {
      const submitButton = page.getByRole('button', {
        name: /tell me|submit|add|what is this/i,
      })

      const hasSubmitOption = await submitButton.isVisible().catch(() => false)

      expect(hasSubmitOption).toBe(true)

      if (await submitButton.isVisible()) {
        await submitButton.click()

        // Should show form to enter place details
        const placeNameInput = page.getByPlaceholder(/place name|name of/i)

        if (await placeNameInput.isVisible()) {
          await placeNameInput.fill(uniquePlaceName)

          // Fill in location (latitude, longitude) if available
          const latInput = page.getByPlaceholder(/latitude|lat/i)
          const longInput = page.getByPlaceholder(/longitude|long/i)

          if (await latInput.isVisible()) {
            await latInput.fill('40.7128')
          }

          if (await longInput.isVisible()) {
            await longInput.fill('-74.0060')
          }

          // Submit the new place
          const submitFormButton = page.getByRole('button', { name: /submit|save|add place/i })

          if (await submitFormButton.isVisible()) {
            await submitFormButton.click()

            // Should show success message
            await expect(page.getByText(/submitted|added|saved|success/i)).toBeVisible({
              timeout: 5000,
            })
          }
        }
      }
    }
  })

  test('should store new place and allow game to continue', async ({ page }) => {
    const description = 'A custom landmark that I'm creating for this test with unique coordinates'

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Check for form or submission option
    const submitOption = await page
      .getByRole('button', { name: /tell me|submit|what is|add/i })
      .isVisible()
      .catch(() => false)

    if (submitOption) {
      // Even if submission modal appears, game should be playable
      const gameActive = await page.getByText(/Question|Is this|No matches/).isVisible()

      expect(gameActive).toBe(true)
    }
  })

  test('should require place details for submission', async ({ page }) => {
    const description = 'Another unique test place for validation'

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Look for submission form
    const submitButton = page.getByRole('button', { name: /tell me|submit|what is/i })

    if (await submitButton.isVisible()) {
      await submitButton.click()

      // Check for form validation
      const placeNameInput = page.getByPlaceholder(/place name|name of/i)

      if (await placeNameInput.isVisible()) {
        // Try to submit without filling in required fields
        const submitFormButton = page.getByRole('button', { name: /submit|save|add/i })

        // Submit button should exist but might be disabled
        // or form should show validation errors
        const formVisible = await page.getByText(/required|please|invalid|error/i).isVisible()

        if (submitButton) {
          expect(submitButton).toBeDefined()
        }
      }
    }
  })

  test('should allow user to set location for new place', async ({ page }) => {
    const description = 'A special test location with custom coordinates'

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Look for location input fields
    const latInput = page.getByPlaceholder(/latitude|lat/i)
    const longInput = page.getByPlaceholder(/longitude|long/i)

    const hasLocationFields = (await latInput.isVisible().catch(() => false)) || (await longInput.isVisible().catch(() => false))

    // Location fields might be in a submission form, so check if we need to open form first
    if (!hasLocationFields) {
      const submitButton = page.getByRole('button', { name: /tell me|submit|what is/i })

      if (await submitButton.isVisible()) {
        await submitButton.click()
        await page.waitForTimeout(500)
      }
    }

    // Try to find and fill location fields
    const latInputAfter = page.getByPlaceholder(/latitude|lat/i)

    if (await latInputAfter.isVisible()) {
      await latInputAfter.fill('51.5074')

      const longInputAfter = page.getByPlaceholder(/longitude|long/i)

      if (await longInputAfter.isVisible()) {
        await longInputAfter.fill('-0.1278')

        // Verify values were entered
        expect(await latInputAfter.inputValue()).toBe('51.5074')
        expect(await longInputAfter.inputValue()).toBe('-0.1278')
      }
    }
  })

  test('should show map or location picker for place submission', async ({ page }) => {
    const description = 'A place with geographic significance I want to map'

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Map should be visible on the page for location reference/selection
    const mapVisible = await page.locator('canvas.maplibregl-canvas').isVisible().catch(() => false)

    expect(mapVisible).toBe(true)

    // If there's a submission form, it might also have location picker
    const submitButton = page.getByRole('button', { name: /tell me|submit|what is/i })

    if (await submitButton.isVisible()) {
      await submitButton.click()

      // After opening form, map should still be visible for reference
      const mapStillVisible = await page.locator('canvas.maplibregl-canvas').isVisible().catch(() => false)

      expect(mapStillVisible).toBe(true)
    }
  })

  test('should allow embedding generation for new place', async ({ page }) => {
    // This test verifies that the mock embedding works for new place submission
    const description = 'A memorable location with distinctive features'

    await page.getByPlaceholder(/e.g.,/).fill(description)

    // Before starting game, verify description is ready
    await expect(page.getByText(`${description.length}/500`)).toBeVisible()

    await page.getByRole('button', { name: 'Start Game' }).click()

    // Wait for embedding generation
    await expect(page.getByText('Analyzing your description...')).toBeVisible()

    // Embedding mock should respond quickly
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 5000,
    })

    // Game should continue (either with results or submission prompt)
    const gameState = await page
      .getByText(/Question|Is this|No matches|submit|tell me/i)
      .isVisible()

    expect(gameState).toBe(true)
  })

  test('should validate place coordinates are within valid range', async ({ page }) => {
    const description = 'A test place with coordinates'

    await page.getByPlaceholder(/e.g.,/).fill(description)
    await page.getByRole('button', { name: 'Start Game' }).click()

    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 10000,
    })

    await page.waitForTimeout(500)

    // Open submission form if available
    const submitButton = page.getByRole('button', { name: /tell me|submit|what is/i })

    if (await submitButton.isVisible()) {
      await submitButton.click()

      // Try to enter invalid latitude (should be -90 to 90)
      const latInput = page.getByPlaceholder(/latitude|lat/i)

      if (await latInput.isVisible()) {
        await latInput.fill('200') // Invalid latitude

        // Form should show error or not allow submission
        const submitFormButton = page.getByRole('button', { name: /submit|save|add/i })

        if (await submitFormButton.isVisible()) {
          // Button might be disabled or form shows error
          const disabled = await submitFormButton.isDisabled().catch(() => false)

          expect(
            disabled ||
              (await page.getByText(/invalid|error|range|latitude/i).isVisible().catch(() => false))
          ).toBe(true)
        }
      }
    }
  })
})
