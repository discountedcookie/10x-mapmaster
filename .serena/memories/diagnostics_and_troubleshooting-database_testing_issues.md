# Database Testing Setup

## Overview

Complete database testing suite for session-first architecture using pgTAP framework. Tests validate core RPC functions, views, and game flow logic.

## Test Files

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

## Bugs Fixed During Testing

### 1. Question Effectiveness Logic Bug
**File**: `supabase/migrations/000003_database_functions.sql`
**Function**: `update_question_effectiveness_batch()`

**Problem**: Original formula divided by 2.0, causing ALL effectiveness scores to decrease:
```sql
-- BROKEN
effectiveness_score = (effectiveness_score + effectiveness_delta) / 2.0
-- Result: 0.5 + 0.1 = 0.6 / 2.0 = 0.3 (decreased!)
```

**Fix 1 - Handle NULL candidates_before**: First question has no previous state, assume 20 initial candidates:
```sql
IF answer_record.candidates_before IS NULL THEN
  initial_candidate_count := 20;
ELSE
  initial_candidate_count := jsonb_array_length(
    answer_record.candidates_before->'place_ids'
  );
END IF;
```

**Fix 2 - Correct learning rate formula**:
```sql
-- FIXED - learning rate of 0.2
effectiveness_score = LEAST(1.0, GREATEST(0.0, 
  effectiveness_score + 0.2 * effectiveness_delta
))
```

**Results**:
- Good question: 0.5 → 0.52 (+0.02 with delta +0.1) ✅
- Bad question: 0.5 → 0.46 (-0.04 with delta -0.2) ✅
- Neutral question: 0.5 → 0.49 (-0.01 with delta -0.05) ✅

### 2. PostgreSQL UUID Aggregation
**File**: `supabase/tests/test_session_first.sql` (before TAP conversion)

**Problem**: `MIN(id)` doesn't work on UUID type
```sql
SELECT COUNT(*), MIN(id) INTO candidate_count, remaining_place
FROM get_candidates(test_session_id);
-- ERROR: function min(uuid) does not exist
```

**Fix**: Separate queries
```sql
SELECT COUNT(*) INTO candidate_count FROM get_candidates(test_session_id);
SELECT id INTO remaining_place FROM get_candidates(test_session_id) LIMIT 1;
```

### 3. Multi-row INSERT RETURNING
**Problem**: Can't capture multiple UUIDs with single RETURNING clause
```sql
INSERT INTO places VALUES (...), (...), (...)
RETURNING id INTO place1_id, place2_id, place3_id; -- ERROR
```

**Fix**: Separate INSERT statements OR use temp table (TAP version uses temp table approach)

## Test Data Strategy

**Philosophy**: Tests should be self-contained and not depend on seed data enrichment.

**Approach**:
1. Each test file creates minimal test data in transaction
2. Uses `test_dummy_embedding()` helper for vector(384) values
3. Transaction ROLLBACK ensures no pollution between test runs
4. Seed data (from migrations) is available but not required

**Example**:
```sql
BEGIN; -- Start transaction

CREATE OR REPLACE FUNCTION test_dummy_embedding()
RETURNS vector(384) AS $$
  SELECT array_fill(0.1::float, ARRAY[384])::vector(384);
$$ LANGUAGE sql;

-- Create test data
INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'test@example.com');
INSERT INTO places (name, lat, lng, descriptors, embedding) 
VALUES ('Test Place', 48.8584, 2.2945, '{}'::jsonb, test_dummy_embedding());

-- Run tests
SELECT is(...);

ROLLBACK; -- Clean up
```

## Package.json Script

```json
{
  "scripts": {
    "test:db": "npx supabase test db"
  }
}
```

## Deprecated Tests Removed

- `test_filtering.sql` - Used old `filter_candidates_with_history` function
- `test_tallest_mountains.sql` - Used old filtering logic

Both replaced by session-first `get_candidates()` approach.

## Next Steps (Future)

1. Convert `test_question_effectiveness.sql` to pgTAP format
2. Add E2E tests for complete game flow (start → questions → guess → finalize)
3. Add tests for `update_place_embedding()` learning function
4. Add RLS policy tests (verify users can't access others' sessions)
5. Add performance tests for vector similarity at scale

## Known Limitations

- Tests show "Parse errors: No plan found in TAP output" for non-TAP files
- This is cosmetic - all assertions still validate correctly
- Exit code reflects test failures, not format warnings
