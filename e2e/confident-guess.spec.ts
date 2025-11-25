import { test, expect, handleAuth } from './fixtures'

test.describe('V2 Confident Guess Test', () => {
  test.beforeEach(async ({ page }) => {
    // Mock start_game RPC to return active with guess
    await page.route('**', async (route) => {
      const url = route.request().url()
      const method = route.request().method()
      if (method === 'POST' && url.includes('start_game')) {
        console.log('Mocking confident guess start_game RPC:', url)
        await route.fulfill({
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
            semantic_constraint:
              "The iconic iron lattice tower built for the 1889 World's Fair in Paris",
          }),
        })
      } else {
        await route.continue()
      }
    })

    // Mock play_turn RPC for confirming guess (YES)
    await page.route('**', async (route) => {
      const url = route.request().url()
      const method = route.request().method()
      if (method === 'POST' && url.includes('play_turn')) {
        const body = route.request().postDataJSON()
        console.log('Mocking play_turn RPC:', url, 'body:', body)

        // If confirming guess (is_correct = true)
        if (body?.is_correct === true) {
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
              semantic_constraint:
                "The iconic iron lattice tower built for the 1889 World's Fair in Paris",
            }),
          })
        } else {
          // If rejecting guess (is_correct = false)
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
              semantic_constraint:
                "The iconic iron lattice tower built for the 1889 World's Fair in Paris. Denied: Eiffel Tower",
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

  test('should show guess confirmation (not auto-win)', async ({ page }) => {
    // Enter description that should match Eiffel Tower with >95% confidence
    const description = "The iconic iron lattice tower built for the 1889 World's Fair in Paris"
    await page.getByPlaceholder(/Describe a place/).fill(description)

    // Start game
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Reading your clues...')).toBeVisible()
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should show guess confirmation (not auto-win)
    await expect(page.getByText('Is this it?')).toBeVisible()
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Should show confidence meter at high level
    const confidenceMeter = page.locator('[data-testid="confidence-meter"]')
    await expect(confidenceMeter).toBeVisible()

    // Should have confirmation buttons (not auto-win)
    const confirmButton = page.getByRole('button', { name: /Yeah|Yes|That's it/ })
    const rejectButton = page.getByRole('button', { name: /No|Not it/ })
    await expect(confirmButton).toBeVisible()
    await expect(rejectButton).toBeVisible()
  })

  test('should accept guess and win game', async ({ page }) => {
    const description = "The iconic iron lattice tower built for the 1889 World's Fair in Paris"
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess to appear
    await expect(page.getByText('Is this it?')).toBeVisible()
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Confirm correct guess
    await page.getByRole('button', { name: /Yeah|Yes|That's it/ }).click()

    // Should show success message
    await expect(page.getByText(/Game saved|You won|Correct/i)).toBeVisible({
      timeout: 5000,
    })
  })

  test('should reject guess and continue game', async ({ page }) => {
    const description = "The iconic iron lattice tower built for the 1889 World's Fair in Paris"
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for guess to appear
    await expect(page.getByText('Is this it?')).toBeVisible()
    await expect(page.getByText(/Eiffel Tower/i)).toBeVisible()

    // Reject guess
    await page.getByRole('button', { name: /No|Not it/ }).click()

    // Should continue with a question instead of ending
    await expect(page.getByText(/Question|Is it/i)).toBeVisible({ timeout: 5000 })

    // Should NOT show game over or success
    await expect(page.getByText(/Game Over|You won/i)).not.toBeVisible()
  })

  test('should respect margin safeguard (0.05 gap)', async ({ page }) => {
    // Mock embeddings to return two candidates with close confidence scores
    await page.route('**/functions/v1/generate-embedding', async (route) => {
      const request = route.request()
      if (request.method() === 'POST') {
        // Return embedding that creates candidates with gap < 0.05
        const embedding = Array.from({ length: 1024 }).fill(0)
        embedding[0] = 0.88 // Creates close matches
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ embedding }),
        })
      } else {
        await route.continue()
      }
    })

    // Enter description that should create multiple high-confidence candidates
    const description = 'A famous tower in a major European city'
    await page.getByPlaceholder(/Describe a place/).fill(description)
    await page.getByRole('button', { name: "Let's Go!" }).click()

    // Wait for processing
    await expect(page.getByText('Analyzing your description...')).not.toBeVisible({
      timeout: 15_000,
    })

    // Should NOT guess immediately due to margin safeguard
    // Should instead ask a question to differentiate candidates
    await expect(page.getByText('Question 1 of')).toBeVisible()
    await expect(page.getByText('Is this it?')).not.toBeVisible()
  })
})
