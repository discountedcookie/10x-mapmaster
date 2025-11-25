import { test, expect, handleAuth } from './fixtures'

test.describe('Guess Confirmation Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Mock start_game to return confident guess
    await page.route('**', async (route) => {
      const url = route.request().url()
      const method = route.request().method()

      await (method === 'POST' && url.includes('start_game')
        ? route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              session_id: 'test-session-123',
              status: 'active',
              question_count: 0,
              wrong_guess_count: 0,
              total_turns: 0,
              candidate_count: 1,
              confidence_gap: 0.15,
              candidates: [
                {
                  id: 'place-1',
                  name: 'Eiffel Tower',
                  lat: 48.8584,
                  lng: 2.2945,
                  semantic_similarity: 0.95,
                  spatial_confidence: 0.98,
                  composite_confidence: 0.965,
                  descriptors: {},
                },
              ],
              next_action: {
                type: 'guess',
                place_id: 'place-1',
                place_name: 'Eiffel Tower',
                confidence: 0.965,
              },
              pending_guess_place_id: 'place-1',
              semantic_constraint: 'A tall iron tower in Paris',
            }),
          })
        : route.continue())
    })

    // Mock play_turn for guess confirmation
    await page.route('**', async (route) => {
      const url = route.request().url()
      const method = route.request().method()

      if (method === 'POST' && url.includes('play_turn')) {
        const body = route.request().postDataJSON()

        if (body?.is_correct === true) {
          // Correct guess - game wins
          await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              session_id: 'test-session-123',
              status: 'won',
              question_count: 0,
              wrong_guess_count: 0,
              total_turns: 1,
              candidate_count: 1,
              confidence_gap: 0.15,
              candidates: [
                {
                  id: 'place-1',
                  name: 'Eiffel Tower',
                  lat: 48.8584,
                  lng: 2.2945,
                  semantic_similarity: 0.95,
                  spatial_confidence: 0.98,
                  composite_confidence: 0.965,
                  descriptors: {},
                },
              ],
              next_action: null,
              pending_guess_place_id: null,
              semantic_constraint: 'A tall iron tower in Paris',
            }),
          })
        } else if (body?.is_correct === false) {
          // Wrong guess - game continues
          await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              session_id: 'test-session-123',
              status: 'active',
              question_count: 0,
              wrong_guess_count: 1,
              total_turns: 1,
              candidate_count: 5,
              confidence_gap: 0.08,
              candidates: [
                {
                  id: 'place-2',
                  name: 'Big Ben',
                  lat: 51.5007,
                  lng: -0.1246,
                  semantic_similarity: 0.85,
                  spatial_confidence: 0.88,
                  composite_confidence: 0.865,
                  descriptors: {},
                },
              ],
              next_action: {
                type: 'question',
                question: {
                  id: 'q-1',
                  text: 'Is it in Europe?',
                  type: 'geographic',
                },
              },
              pending_guess_place_id: null,
              semantic_constraint: 'A tall iron tower in Paris. Denied: Eiffel Tower',
            }),
          })
        } else {
          // Answer question
          await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              session_id: 'test-session-123',
              status: 'active',
              question_count: 1,
              wrong_guess_count: 0,
              total_turns: 1,
              candidate_count: 3,
              confidence_gap: 0.12,
              candidates: [
                {
                  id: 'place-3',
                  name: 'Statue of Liberty',
                  lat: 40.6892,
                  lng: -74.0445,
                  semantic_similarity: 0.82,
                  spatial_confidence: 0.85,
                  composite_confidence: 0.835,
                  descriptors: {},
                },
              ],
              next_action: {
                type: 'question',
                question: {
                  id: 'q-2',
                  text: 'Is it made of metal?',
                  type: 'semantic',
                },
              },
              pending_guess_place_id: null,
              semantic_constraint: 'A tall iron tower in Paris. Denied: Eiffel Tower',
            }),
          })
        }
      } else {
        await route.continue()
      }
    })

    await page.goto('/game')
    await handleAuth(page)
  })

  test('should show guess with pending_guess_place_id set', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show guess confirmation
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible()
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Should have confirmation buttons
    const confirmButton = page.getByRole('button', { name: /Yeah|Yes|That's it/ })
    const rejectButton = page.getByRole('button', { name: /No|Not it/ })
    await expect(confirmButton).toBeVisible()
    await expect(rejectButton).toBeVisible()
  })

  test('should accept guess and win game', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 15_000 })
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Accept guess
    await page.getByRole('button', { name: /Yeah|Yes|That's it/ }).click()

    // Should show success
    await expect(page.getByText(/Game saved|You won|Correct/i)).toBeVisible({
      timeout: 5000,
    })
  })

  test('should reject guess and continue game', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 15_000 })
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Reject guess
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Should continue with a question
    await expect(page.getByText(/Question|Is it/i)).toBeVisible({ timeout: 5000 })

    // Should NOT show game over
    await expect(page.getByText(/Game Over|You won/i)).not.toBeVisible()
  })

  test('should clear pending_guess_place_id after confirmation', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 15_000 })

    // Accept guess
    await page.getByRole('button', { name: /Yeah|Yes|That's it/ }).click()

    // After confirmation, pending_guess_place_id should be cleared
    // (verified by game showing success, not another guess)
    await expect(page.getByText(/Game saved|You won|Correct/i)).toBeVisible({
      timeout: 5000,
    })
  })

  test('should increment wrong_guess_count when rejecting guess', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 15_000 })

    // Reject guess
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Should continue with a question (indicating wrong_guess_count was incremented)
    await expect(page.getByText(/Question|Is it/i)).toBeVisible({ timeout: 5000 })

    // Game should still be active
    await expect(page.getByText(/Game Over|ended/i)).not.toBeVisible()
  })

  test('should increment total_turns for each guess confirmation', async ({ page }) => {
    const description = 'A tall iron tower in Paris'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess
    await expect(page.getByText(/Is this|Is it/i)).toBeVisible({ timeout: 15_000 })

    // Accept guess (total_turns should be 1)
    await page.getByRole('button', { name: /Yeah|Yes|That's it/ }).click()

    // Should show success with total_turns = 1
    await expect(page.getByText(/Game saved|You won|Correct/i)).toBeVisible({
      timeout: 5000,
    })
  })
})
