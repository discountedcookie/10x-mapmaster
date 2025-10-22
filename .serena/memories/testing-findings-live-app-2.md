# Game Testing Findings - January 21, 2025

## Executive Summary

Comprehensive manual testing revealed a **critical bug in the candidate filtering system** that causes the game to fail for existing database places while working correctly for newly-added places.

## Test Environment
- **URL**: http://localhost:5173/
- **User**: piotr.ciastko@pm.me
- **Date**: January 21, 2025
- **Database**: 22 seed places + questions

---

## Test Results

### Test 1: Eiffel Tower (Existing Place)
**Description**: "A tall metal structure in a European capital, very famous landmark"

**Outcome**: ❌ FAILED
- All 5 questions showed "**0 possible places remaining**"
- Confidence: "Low (0%)" throughout
- Final result: "No matches found"
- **Critical**: Eiffel Tower IS in database, description matches, but system shows 0 candidates

**Questions Asked**:
1. Is it in Europe? → YES
2. Is it in Africa? → NO
3. Is it near an ocean or sea? → NO
4. Is it very tall (over 200 meters)? → YES
5. Was it built in ancient times? → NO

### Test 2: Taj Mahal (Existing Place)
**Description**: "A beautiful white building in Asia, famous monument"

**Outcome**: ❌ FAILED
- **Initial**: Pyramids of Giza (49% match) - WRONG but shows system CAN match
- **After Q1 (No to Africa)**: Drops to "0 possible places remaining"
- Same filtering bug as Test 1
- Final result: "No matches found"

**Questions Asked**:
1. Is it in Africa? → NO (Taj Mahal is in Asia)
2. Is it in Europe? → NO
3. Is it very tall (over 200 meters)? → NO
4. Is it near an ocean or sea? → NO
5. Was it built in ancient times? → NO

### Test 3: Angel Falls (NEW Place - Not in Database)

#### Part A - Before Adding
**Outcome**: ❌ FAILED
- Initial: Pyramids of Giza (46% match)
- After answering questions: "0 possible places remaining"
- Same bug pattern

#### Part B - After Adding to Database
**Description**: "A very tall waterfall in South America, one of the highest in the world"

**Outcome**: ✅ SUCCESS!
- **Angel Falls identified with 60% confidence**
- Map shows only Angel Falls marker in Venezuela
- "1 possible place remaining" (CORRECT - not 0!)
- Confidence level: "Medium (60%)"

**Question Asked**:
1. Is it in Africa? → Ready to answer (test stopped here to document success)

---

## Critical Bugs Identified

### 1. Candidate Filtering System Failure (CRITICAL)
**Symptom**: "0 possible places remaining" for ALL existing database places

**Evidence**:
- Eiffel Tower: 0 candidates from start
- Taj Mahal: 49% initial → 0 after first filter
- Angel Falls (NEW): 60% and working correctly

**Pattern**:
- Initial semantic search sometimes works (Pyramids of Giza found at 46-49%)
- After answering ANY question with filtering, drops to 0 candidates
- Only affects PRE-EXISTING places
- Newly-added places work perfectly

**Root Cause Hypothesis**:
1. **Seed embeddings corrupted**: Migration `000003_seed_embeddings.sql` might have bad data
2. **Filtering logic bug**: The hybrid filtering (semantic + geographic + question-based) over-filters
3. **Type mismatch**: Coordinate or question answer type causing filter to exclude all results
4. **Question embedding mismatch**: Pre-seeded question embeddings don't match new embedding generation

### 2. Backend API Errors
**Evidence**:
- **400 error** when selecting Eiffel Tower after search
- **406 error** when selecting Angel Falls after search
- Both from Supabase endpoints (URLs: https://lrrcfzyjtejj...)

**Impact**:
- Despite errors, Angel Falls was successfully added (success toast shown)
- Eiffel Tower selection failed silently
- Suggests edge function or RPC endpoint issues

### 3. Map Marker Behavior
**Working correctly**:
- Shows 22 initial markers on home/game start
- Filters to 1 marker when candidate found (Pyramids, Angel Falls)
- Updates real-time during game

**Bug**:
- When "0 possible places remaining", shows ALL 22 markers
- Should show 0 markers or indicate no matches visually

---

## What Works Correctly

1. ✅ **Authentication** - Login/logout flow functional
2. ✅ **Map Visualization** - MapLibre renders 22 markers correctly
3. ✅ **Question Flow** - All 5 questions display, progress bar updates
4. ✅ **Nominatim Integration** - Place search finds locations (Angel Falls, Eiffel Tower variants)
5. ✅ **Add Place Feature** - Successfully added Angel Falls to database
6. ✅ **Semantic Matching for NEW Places** - Angel Falls matched at 60%!
7. ✅ **Initial Candidate Search** - Can find first match (Pyramids at 46-49%)

---

## Key Observations

### The "New vs Old" Pattern
**Critical insight**: The algorithm works ONLY for newly-added places

| Place | Status | Result | Confidence |
|-------|--------|--------|------------|
| Eiffel Tower | Seed data | ❌ 0 matches | 0% |
| Taj Mahal | Seed data | ❌ 0 matches | 0% |
| Angel Falls | Newly added | ✅ 1 match | 60% |

**Implication**: The bug is NOT in the core algorithm, but in how seed data is processed/stored

### Filtering Cascade Failure
1. **Step 1** (Initial search): Sometimes works, finds Pyramids of Giza
2. **Step 2** (First filter): Drops to 0 candidates
3. **Step 3+** (Subsequent filters): Remains at 0

**Hypothesis**: First filter operation corrupts the candidate set or uses incompatible data

---

## Data Quality Issues

### Seed Embeddings Suspect
File: `supabase/migrations/000003_seed_embeddings.sql`

**Evidence it might be bad**:
- Generated embeddings don't work
- Manual embedding (Angel Falls) works perfectly
- Suggests generation script produced invalid vectors

**Action Required**: 
1. Check embedding generation script: `scripts/generate-seed-embeddings.ts`
2. Verify vector dimensions (should be 384 for gte-small)
3. Regenerate embeddings and test

### Question Embeddings
File: `supabase/migrations/000002_seed_questions.sql`

**Concern**: Pre-seeded questions might have:
- Missing embeddings (NULL values)
- Wrong dimensionality
- Incompatible format with runtime embedding generation

---

## Frontend Issues

### User Experience Bugs
1. **Misleading "0 possible places remaining"** - Should say "Search failed" or similar
2. **All markers shown when 0 candidates** - Confusing UX
3. **No visual feedback for algorithm failure** - Silent failure until end
4. **Error toasts not shown** - 400/406 errors don't notify user

### Console Warnings
Multiple Vue warnings: "Extraneous non-props attributes (class) were passed to component"
- Not critical but should be cleaned up

---

## Recommended Investigation Order

### Priority 1: Embeddings (MOST LIKELY)
1. Inspect `000003_seed_embeddings.sql` - check vector format
2. Verify embedding dimensions match (384)
3. Query database directly to check actual embedding values
4. Compare seed embedding to Angel Falls embedding (working one)

### Priority 2: Filtering Logic
1. Review candidate filtering in `src/stores/game.ts`
2. Check SQL functions in database migrations
3. Test filtering with Angel Falls vs Eiffel Tower
4. Add console.log debugging to see where candidates disappear

### Priority 3: Question Matching
1. Verify question embeddings exist and are valid
2. Check how question answers filter candidates
3. Test question filtering independently

### Priority 4: Backend Errors
1. Investigate 400/406 errors from Supabase
2. Check edge function logs
3. Verify RPC function parameters and types

---

## Testing Commands for Investigation

```bash
# Check database embeddings
npx supabase db reset
psql -h localhost -p 54322 -U postgres -d postgres -c "SELECT name, array_length(embedding, 1) FROM places WHERE name = 'Eiffel Tower';"

# Regenerate embeddings
npm run generate:seed-migration

# Test with fresh data
npx supabase db reset
npm run dev
# Try game with Eiffel Tower again

# Check logs
npx supabase functions serve
# Watch for errors during game play
```

---

## Algorithm Refactor Goals

Based on findings, the refactor should:

1. **Fix seed embedding generation** - Ensure valid 384-dim vectors
2. **Improve filtering logic** - Don't drop to 0 candidates inappropriately
3. **Add debugging** - Log candidate counts at each filtering step
4. **Fallback handling** - Gracefully handle 0 candidates mid-game
5. **Better error handling** - Surface backend errors to user
6. **Consistent behavior** - Same logic for seed vs user-added places
7. **Type safety** - Ensure coordinate/answer types match between frontend/backend

---

## Success Criteria for Refactor

✅ Eiffel Tower description matches correctly (>50% confidence)
✅ Taj Mahal description matches correctly (>50% confidence)
✅ No "0 possible places remaining" unless truly no matches
✅ Candidates decrease logically after each question
✅ No 400/406 backend errors
✅ Consistent behavior between seed and user-added places
✅ All existing E2E tests pass
✅ Manual testing with 5+ different places succeeds
