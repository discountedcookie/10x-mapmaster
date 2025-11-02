# E2E Testing with Embedding Mock

This guide explains how the E2E tests are set up with mocked vector embeddings for local development.

## Problem

The `generate-embedding` edge function requires Supabase's AI runtime (using the `gte-small` model to generate 384-dimensional vectors), which is not available in local Supabase instances. This prevented E2E tests from running locally.

## Solution

We've implemented network request mocking using Playwright's `page.route()` API to intercept calls to the `generate-embedding` edge function and return deterministic mock embeddings.

## How It Works

### 1. Mock Embeddings Generator (`e2e/fixtures/mock-embeddings.ts`)

The `generateMockEmbedding(text: string)` function:
- Takes the input text and generates a deterministic embedding vector
- Uses SHA256 hash of the input as a seed for reproducible results
- Always returns a 384-dimensional vector (matching the real gte-small model)
- Ensures same input → same embedding for test reproducibility

Example:
```typescript
const embedding1 = generateMockEmbedding("Eiffel Tower")
const embedding2 = generateMockEmbedding("Eiffel Tower")
// embedding1 === embedding2 ✓ (deterministic)
```

### 2. Playwright Fixture (`e2e/fixtures/index.ts`)

Extends Playwright's test runner with automatic embedding mocking:
```typescript
import { test, expect } from './fixtures'  // Use custom fixture

test('my test', async ({ page }) => {
  // Embedding mock is automatically set up
  // All calls to generate-embedding are intercepted and mocked
})
```

The fixture automatically:
- Intercepts requests to `**/functions/v1/generate-embedding`
- Returns a mock embedding for the provided text
- Falls back to real request if mocking fails

### 3. Network Route Interception

How the mock works:
```
User Input
    ↓
useEmbeddings.generateEmbedding(text)
    ↓
supabase.functions.invoke('generate-embedding')
    ↓
HTTP POST to /functions/v1/generate-embedding
    ↓
[Playwright route intercepts]
    ↓
generateMockEmbedding(text)
    ↓
Returns: { embedding: [0.1, 0.2, ..., 0.384] }
```

## Running E2E Tests Locally

### Prerequisites

```bash
# Install dependencies
npm install

# Start local Supabase (if not already running)
supabase start

# Start dev server (required by playwright.config.ts)
npm run dev
```

### Run Tests

```bash
# Run all E2E tests
npm run test:e2e

# Run specific test file
npm run test:e2e -- e2e/complete-game-flow.spec.ts

# Run with UI mode for debugging
npm run test:e2e -- --ui

# Run in headed mode (see browser)
npm run test:e2e -- --headed
```

### Test Files

- **`e2e/home.spec.ts`** - Home page navigation and map rendering
- **`e2e/complete-game-flow.spec.ts`** - Full game flow (sign up, describe place, answer questions, guess result)
- **`e2e/eiffel-tower-test.spec.ts`** - Specific Eiffel Tower scenario test

## Key Features

### Deterministic Embeddings

Same text always produces the same embedding:
```typescript
// Same across test runs, deterministic for assertions
const emb1 = generateMockEmbedding("A tall tower")
const emb2 = generateMockEmbedding("A tall tower")
expect(emb1).toEqual(emb2) ✓
```

### Error Handling

If the mock encounters an error:
1. Logs the error to console for debugging
2. Falls back to attempting the real edge function
3. This allows graceful degradation if setup changes

### Performance

Mock embeddings are generated instantly (no network delay):
- Faster test execution
- Consistent timing (no flakiness from network)
- Suitable for CI/CD pipelines

## Verifying the Mock Works

### 1. Check Network Tab
In Playwright UI mode or with `--headed` flag:
1. Run tests: `npm run test:e2e -- --headed`
2. Open DevTools (F12)
3. Check Network tab for `/functions/v1/generate-embedding` requests
4. Status should show the request was fulfilled (not real network call)

### 2. Verify Embedding Content
The mock embedding will be:
- Always 384 elements long ✓
- Floating point numbers in range -1 to 1 ✓
- Same for same input text ✓

### 3. Test Output
Look for successful game flow completion:
```
✓ should complete game with successful guess
✓ should handle invalid description input
✓ should show loading state during embedding generation
✓ should display map with candidate markers
```

## Debugging

### If tests fail with embedding errors:

1. **"Invalid embedding response"** - Check that mock is returning 384-element array
   ```typescript
   // Verify in fixtures/mock-embeddings.ts
   embedding.length === 384 ✓
   ```

2. **"HTTP 404 on edge function"** - Check route pattern
   ```typescript
   // Pattern must match actual URL
   '**/functions/v1/generate-embedding' ✓
   ```

3. **"Edge function not mocked"** - Ensure tests import from `./fixtures`
   ```typescript
   // ✓ Correct
   import { test, expect } from './fixtures'

   // ❌ Wrong
   import { test, expect } from '@playwright/test'
   ```

### Enable Debug Logging

```bash
# Run with debug output
npm run test:e2e -- --debug

# Or with trace enabled
npm run test:e2e -- --trace on
```

## Integration with Game Logic

The mock embeddings integrate seamlessly with the game's RPC functions:

1. **Text Input** → "A famous tower in Paris"
2. **Mock Embedding** → 384-dimensional vector
3. **Database Query** → `match_places()` RPC with mock embedding
4. **Results** → Game candidates returned

The mock embeddings have sufficient semantic separation to produce different matches for different descriptions.

## Future Enhancements

### 1. More Sophisticated Mocking
- Could implement actual semantic similarity (e.g., using local embeddings library)
- Current deterministic approach is sufficient for E2E testing

### 2. Embedding Verification Tests
- Could add tests that verify embedding properties
- Ensure vector normalization, dimension correctness

### 3. Performance Benchmarking
- Mock provides baseline performance
- Could compare with real edge function performance in staging

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# .github/workflows/test.yml
- name: Run E2E tests
  run: npm run test:e2e
  env:
    CI: true
    # Tests automatically use mocked embeddings
```

The mock works in CI without any special configuration - just run `npm run test:e2e`.

## Related Files

- **Fixture:** `e2e/fixtures/index.ts` - Custom test extension
- **Mock Logic:** `e2e/fixtures/mock-embeddings.ts` - Embedding generation
- **Config:** `playwright.config.ts` - Playwright configuration
- **Tests:** `e2e/*.spec.ts` - Test files using the fixture

## Summary

✅ E2E tests can now run locally without vector embeddings
✅ Deterministic mocking ensures reproducible test results
✅ No changes needed to application code
✅ Seamless integration with existing test files
✅ Works in CI/CD without configuration
