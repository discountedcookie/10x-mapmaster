import { Page } from '@playwright/test'

/**
 * Mock Supabase RPC responses for E2E tests
 */

// Cold start scenario: empty database, needs place submission
export async function setupColdStartMock(page: Page) {
  // Mock start_game RPC to return needs_submission
  await page.route('**/rest/v1/rpc/start_game', async (route) => {
    await (route.request().method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'needs_submission',
            question_count: 0,
            candidate_count: 0,
            confidence_gap: 0,
            candidates: [],
            semantic_constraint: 'A unique crystal palace in a remote mountain valley',
          }),
        })
      : route.continue())
  })

  // Setup common mocks
  await setupCommonMocks(page)
}

// Confident guess scenario: high confidence, immediate guess
export async function setupConfidentGuessMock(page: Page) {
  // Mock start_game RPC to return active with guess
  await page.route('**/rest/v1/rpc/start_game', async (route) => {
    await (route.request().method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'active',
            question_count: 0,
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
            next_turn: {
              type: 'guess',
              place_id: 'place-1',
              place_name: 'Eiffel Tower',
              confidence: 0.965,
              reason: 'High semantic and spatial confidence match',
            },
            semantic_constraint:
              "The iconic iron lattice tower built for the 1889 World's Fair in Paris",
          }),
        })
      : route.continue())
  })

  // Mock play_turn RPC for confirming guess
  await page.route('**/rest/v1/rpc/play_turn', async (route) => {
    await (route.request().method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'completed',
            question_count: 0,
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
            next_turn: null,
            semantic_constraint:
              "The iconic iron lattice tower built for the 1889 World's Fair in Paris",
          }),
        })
      : route.continue())
  })

  // Setup common mocks
  await setupCommonMocks(page)
}

// Question scenario: ask questions to narrow down
export async function setupQuestionMock(page: Page) {
  // Mock start_game RPC to return active with question
  await page.route('**/rest/v1/rpc/start_game', async (route) => {
    await (route.request().method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'active',
            question_count: 0,
            candidate_count: 3,
            confidence_gap: 0.1,
            candidates: [
              {
                id: 'place-1',
                name: 'Test Place 1',
                lat: 40.7128,
                lng: -74.006,
                semantic_similarity: 0.8,
                spatial_confidence: 0.9,
                composite_confidence: 0.85,
                descriptors: {},
              },
            ],
            next_turn: {
              type: 'question',
              question_text: 'Is it in Europe?',
              question_id: 'q1',
            },
            semantic_constraint: 'A famous tower',
          }),
        })
      : route.continue())
  })

  // Mock play_turn RPC for answering questions
  await page.route('**/rest/v1/rpc/play_turn', async (route) => {
    await (route.request().method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'active',
            question_count: 1,
            candidate_count: 2,
            confidence_gap: 0.12,
            candidates: [
              {
                id: 'place-2',
                name: 'Test Place 2',
                lat: 51.5074,
                lng: -0.1278,
                semantic_similarity: 0.82,
                spatial_confidence: 0.88,
                composite_confidence: 0.85,
                descriptors: {},
              },
            ],
            next_turn: {
              type: 'question',
              question_text: 'Is it a modern structure?',
              question_id: 'q2',
            },
            semantic_constraint: 'A famous tower in Europe',
          }),
        })
      : route.continue())
  })

  // Setup common mocks
  await setupCommonMocks(page)
}

// Legacy function for backward compatibility
export async function setupSupabaseMock(page: Page) {
  await setupQuestionMock(page)
}

// Common mocks used by all scenarios
async function setupCommonMocks(page: Page) {
  // Mock play_turn RPC
  await page.route('**/rest/v1/rpc/play_turn', async (route) => {
    const request = route.request()
    await (request.method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            session_id: 'test-session-123',
            status: 'active',
            question_count: 1,
            candidate_count: 3,
            confidence_gap: 0.1,
            candidates: [
              {
                id: 'place-1',
                name: 'Test Place 1',
                lat: 40.7128,
                lng: -74.006,
                semantic_similarity: 0.8,
                spatial_confidence: 0.9,
                composite_confidence: 0.85,
                descriptors: {},
              },
            ],
            next_turn: {
              type: 'question',
              question_text: 'Is it in Europe?',
              question_id: 'q1',
            },
            semantic_constraint: 'famous tower',
          }),
        })
      : route.continue())
  })

  // Mock add_place RPC
  await page.route('**/rest/v1/rpc/add_place', async (route) => {
    const request = route.request()
    await (request.method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify('place-456'),
        })
      : route.continue())
  })

  // Mock get_candidates RPC
  await page.route('**/rest/v1/rpc/get_candidates', async (route) => {
    const request = route.request()
    await (request.method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              id: 'place-1',
              name: 'Test Place 1',
              lat: 40.7128,
              lng: -74.006,
              semantic_similarity: 0.8,
              spatial_confidence: 0.9,
              composite_confidence: 0.85,
              descriptors: {},
            },
          ]),
        })
      : route.continue())
  })

  // Mock game_sessions table operations
  await page.route('**/rest/v1/game_sessions*', async (route) => {
    const request = route.request()
    if (request.method() === 'POST' || request.method() === 'PATCH') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ error: null }),
      })
    } else if (request.method() === 'GET') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'test-session-123',
            description: 'A test place',
            semantic_constraint: 'test constraint',
            place_id: null,
            was_correct: null,
          },
        ]),
      })
    } else {
      await route.continue()
    }
  })

  // Mock game_answers table operations
  await page.route('**/rest/v1/game_answers*', async (route) => {
    const request = route.request()
    await (request.method() === 'GET'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            { answer_type: 'question_answer' },
            { answer_type: 'question_answer' },
          ]),
        })
      : route.continue())
  })

  // Mock auth endpoints
  await page.route('**/auth/v1/signup', async (route) => {
    const request = route.request()
    await (request.method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            user: {
              id: 'test-user-id',
              email: 'test@example.com',
            },
            session: {
              access_token: 'mock-token',
              refresh_token: 'mock-refresh-token',
            },
          }),
        })
      : route.continue())
  })

  await page.route('**/auth/v1/signin', async (route) => {
    const request = route.request()
    await (request.method() === 'POST'
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            user: {
              id: 'test-user-id',
              email: 'test@example.com',
            },
            session: {
              access_token: 'mock-token',
              refresh_token: 'mock-refresh-token',
            },
          }),
        })
      : route.continue())
  })

  // Mock Nominatim search
  await page.route('https://nominatim.openstreetmap.org/search**', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        {
          place_id: 123,
          display_name: 'Crystal Palace, London, UK',
          lat: '51.4194',
          lon: '-0.0749',
        },
      ]),
    })
  })

  // Mock all Supabase requests - return a valid session for auth
  await page.route('http://127.0.0.1:54321/**', async (route) => {
    const url = route.request().url()
    if (url.includes('/auth/v1/session') && route.request().method() === 'GET') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          session: {
            user: {
              id: '1aa6ffda-39d1-454d-baeb-189895b2fe33',
              email: 'test@example.com',
            },
            access_token: 'mock-token',
            refresh_token: 'mock-refresh-token',
          },
        }),
      })
    } else if (url.includes('/auth/v1/user') && route.request().method() === 'GET') {
      // Mock user validation
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'test-user-id',
          email: 'test@example.com',
        }),
      })
    } else {
      await route.continue()
    }
  })
}
