# Workflow: Testing Guidelines

## Test Stack Overview

| Type | Framework | Location | When to Use |
|------|-----------|----------|-------------|
| **Unit** | Vitest | `src/__tests__/` | Component logic, composables, stores |
| **Database** | pgTAP | `supabase/tests/` | RPC functions, views, RLS policies |
| **E2E** | Playwright | `e2e/` | Full user flows (local only) |

## Test Commands

```bash
# Unit tests (159/159 passing)
npm test
npm run test:unit

# Database tests (25/25 passing)
npm run test:db

# E2E tests (disabled in CI, run locally)
npm run test:e2e

# Type checking
npm run type-check

# Linting
npm run lint

# All quality checks (pre-commit)
/pre_commit_check  # Cursor command
```

## When to Use Each Type

### Unit Tests (Vitest)
**Use for:**
- Component logic (computed properties, methods, event handlers)
- Composables (useEmbeddings, usePlaces, useTheme)
- Store logic (auth, game, places)
- Utility functions (lib/utils.ts)

**Example coverage:**
- `PlaceSearch.spec.ts` - Search input, debouncing, place selection
- `QuestionCard.spec.ts` - Question display, answer buttons, progress
- `useEmbeddings.spec.ts` - Embedding generation, error handling
- `game.spec.ts` - Game state machine, candidate filtering

**Pattern:**
```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import MyComponent from '@/components/MyComponent.vue'

describe('MyComponent', () => {
  it('should render correctly', () => {
    const wrapper = mount(MyComponent)
    expect(wrapper.find('.my-element').exists()).toBe(true)
  })
})
```

### Database Tests (pgTAP)
**Use for:**
- RPC function correctness
- View calculations
- RLS policy enforcement
- Data integrity constraints

**Example coverage:**
- `test_session_first.sql` - Session-first architecture (8 tests)
- `test_match_quality.sql` - Candidate filtering, vector similarity
- `test_question_effectiveness.sql` - Learning system

**Pattern:**
```sql
BEGIN;

-- Setup
CREATE TEMP TABLE test_data (
  user_id uuid,
  session_id uuid
);

INSERT INTO test_data (user_id)
SELECT id FROM auth.users LIMIT 1;

-- Test
SELECT ok(
  (SELECT COUNT(*) FROM get_candidates(test_session_id)) = 3,
  'Should return 3 candidates'
);

ROLLBACK;
```

**Key Features:**
- Uses transactions (ROLLBACK cleans up)
- Self-contained test data (no seed dependency)
- Uses `test_dummy_embedding()` helper for vector(384) values

### E2E Tests (Playwright)
**Use for:**
- Complete user flows
- Integration of frontend + backend
- Visual regression testing
- Cross-browser compatibility

**Status:** Disabled in CI (flaky), run locally only

**Example coverage:**
- `complete-game-flow.spec.ts` - Full game from description to guess
- `eiffel-tower-test.spec.ts` - Specific place testing
- `home.spec.ts` - Homepage rendering, navigation

**Pattern:**
```typescript
import { test, expect } from '@playwright/test'

test('should complete game flow', async ({ page }) => {
  await page.goto('http://localhost:5173/10x-mapmaster/')
  await page.fill('textarea', 'Tall tower in Paris')
  await page.click('button:has-text("Start Game")')
  await expect(page.locator('.question-card')).toBeVisible()
})
```

## RLS Policy Testing

**Method 1: Manual testing in Supabase Dashboard**
1. Open Supabase Studio
2. Go to SQL Editor
3. Run queries as different users:

```sql
-- Test as anonymous user
SELECT * FROM places; -- Should work (public read)
INSERT INTO places VALUES (...); -- Should fail (needs auth)

-- Test as authenticated user
SET request.jwt.claim.sub = '<user-id>';
SELECT * FROM game_sessions; -- Should only see own sessions
```

**Method 2: pgTAP tests (future)**
```sql
-- Create two test users
-- Try to access user1's sessions as user2
-- Assert failure
```

## Test Data Strategy

**Unit tests:**
- Use fixtures and mocks
- Mock Supabase client responses
- No real database dependency

**Database tests:**
- Self-contained in transactions
- Create minimal test data
- Use `test_dummy_embedding()` for vectors
- ROLLBACK ensures cleanup

**E2E tests:**
- Uses local Supabase instance
- Requires seed data (`npm run seed:places`)
- Tests against real database

## Pre-Commit Testing Workflow

**Before every commit:**
```bash
npm run lint          # ESLint (0 warnings)
npm run type-check    # TypeScript (0 errors)
npm test              # Unit tests (159/159 passing)
```

**Before PR merge:**
```bash
npm run test:db       # Database tests (25/25 passing)
npm run test:e2e      # E2E tests (local only)
/review_code_changes  # Cursor command
```

## Known Testing Issues

**Playwright E2E in CI:**
- Tests pass locally but flaky in CI
- Job commented out in `.github/workflows/ci.yml` (lines 94-147)
- Can be re-enabled when CI environment stabilizes

**Database test warnings:**
- "No plan found in TAP output" - cosmetic, tests still validate
- Exit code reflects test failures, not format warnings

## Test Coverage Goals

**Current coverage:**
- Core game flow: ✅ Full coverage
- Database functions: ✅ 25/25 tests passing
- Component logic: ✅ 159/159 tests passing
- E2E flows: ⚠️ Local only (CI disabled)

**Future improvements:**
- RLS policy tests in pgTAP
- Performance tests for vector similarity at scale
- Visual regression tests
- Cross-browser E2E in CI