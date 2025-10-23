## Testing

### Database Testing Setup

**Overview**

Complete database testing suite for session-first architecture using pgTAP framework. Tests validate core RPC functions, views, and game flow logic.

**Test Files**

### `supabase/tests/test_session_first.sql`
**Coverage**: Session-first architecture core functions
**Tests**: 8 tests using pgTAP format

1. **get_candidates() - Initial candidates**: Verifies function returns all test places (not filtered by wrong guesses)
2. **get_next_question()**: Ensures available questions returned (including seed data)
3. **Answer filtering**: Answered questions excluded from next question list
4. **game_session_stats view - question count**: View correctly counts question answers
5. **game_session_stats view - wrong guess count**: View correctly counts wrong guesses
6. **Wrong guess elimination**: Single wrong guess removes place from candidates
7. **Wrong guess exclusion verification**: Eliminated place not in candidate list
8. **Multiple wrong guesses**: Sequential wrong guesses correctly narrow candidates

**Key Pattern**: Uses temp table `test_ids` to store UUIDs, making tests cleaner and more maintainable.

### `supabase/tests/test_question_effectiveness.sql`
**Coverage**: Question learning system
**Tests**: Not yet converted to pgTAP (uses RAISE NOTICE), but fully functional

1. **Effectiveness update after successful game**: 
   - Good question (narrowed candidates, kept target): effectiveness increases
   - Bad question (eliminated all including target): effectiveness decreases
   - Neutral question (no narrowing, kept target): effectiveness slightly decreases
   - Verifies `times_asked` increments

2. **No update on failed session**: Effectiveness unchanged if `was_correct = FALSE`

3. **Bounds checking**: Effectiveness stays within [0.0, 1.0]

## Running Tests

```bash
npm run test:db
# or
npx supabase test db
```

**Prerequisites**: 
- Local Supabase running (`npx supabase start`)
- Database reset not required - tests use transactions with ROLLBACK
- **NO enriched seeds needed** - tests create minimal data with dummy embeddings

### Unit Test Isolation

**Problem**: Unit tests were hitting real Supabase API during test runs.

**Discovery**: Tests were mocking `global.fetch` but composable uses `supabase.functions.invoke()`, which wasn't mocked.

**Solution**: Proper module mocking of `@/lib/supabase`
```typescript
vi.mock('@/lib/supabase', () => ({
  supabase: {
    functions: {
      invoke: vi.fn(),
    },
  },
}))
```

**Impact**:
- Tests now run in complete isolation (no network calls)
- Faster test execution
- Deterministic results (no flaky tests from API issues)
- Proper unit testing practices
- **10/10 tests passing** (was 4/10 before fix)

**Lesson**: Always mock external dependencies at module level, not at lower-level primitives (fetch vs. SDK methods).
