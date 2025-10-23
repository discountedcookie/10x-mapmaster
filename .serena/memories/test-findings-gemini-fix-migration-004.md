# Test Results: Gemini's Fix (Migration 000004)

**Test Date:** 2025-10-23  
**Migration File:** `supabase/migrations/000004_refactor_get_candidates.sql`  
**Test Session IDs:** `8b9aaf40-2994-4b5a-9c5a-6056b57e2f7e`, `d4e0f31f-be30-4cb5-b039-b9a48267a6e6`

---

## Migration Overview

Gemini created a dynamic metadata filtering system to fix the broken semantic question filtering.

### Key Changes

1. **Added `metadata_filter` column to questions table** (line 5)
   - Stores filter logic as JSONB
   - Makes system extensible without SQL changes

2. **Created `apply_metadata_filter()` helper function** (lines 24-73)
   - Applies individual metadata filters
   - Handles three filter types: `type_check`, `numeric_check`, `class_check`
   - Takes: descriptors, metadata_filter, answer
   - Returns: boolean (pass/fail)

3. **Updated `get_candidates()` function** (lines 76-294)
   - Added `metadata_filtered_candidates` CTE (lines 191-200)
   - Placed after geographic filtering, before semantic adjustment
   - Reduced semantic boost ceiling from 1.0→0.95 and multiplier from 0.3→0.1

4. **Pre-configured 3 questions with filters** (lines 11-21)
   - "Is it a bridge or tower?" → type_check
   - "Is it very tall (over 200 meters)?" → numeric_check  
   - "Is it a natural feature?" → class_check

---

## Test Results

### Test 1: Bridge/Tower Filter ✅ WORKS PERFECTLY

**Setup:**
- Description: "Tall iron tower in Paris France"
- Question: "Is it a bridge or tower?" answered YES
- Target: Eiffel Tower (type='tower')

**Initial Candidates (before question):**
1. Eiffel Tower (type='tower') - 0.887 confidence
2. Tower Bridge (type='monument') - 0.826 confidence
3. Burj Khalifa (type='attraction') - 0.822 confidence
4. Colosseum (type='pedestrian') - 0.806 confidence
5. Big Ben (type='clock') - 0.801 confidence

**After Question 1 Filter:**
1. **Eiffel Tower (type='tower')** - 0.950 confidence ✅

**Filtered Out (Correct):**
- ❌ Tower Bridge (type='monument')
- ❌ Burj Khalifa (type='attraction')
- ❌ Colosseum (type='pedestrian')
- ❌ Big Ben (type='clock')
- ❌ All other non-bridge/tower candidates

**Result:** ✅ **PERFECT** - Hard filtering works exactly as intended!

---

### Test 2: Height Filter ❌ DOES NOT WORK

**Setup:**
- Fresh session with same description
- Question: "Is it very tall (over 200 meters)?" answered YES
- Expected: Filter out places under 200m

**After Question 2 Filter:**
1. Eiffel Tower (height: 330m) - 0.943 confidence
2. Burj Khalifa (height: 828m) - 0.903 confidence
3. **Tower Bridge (height: NULL)** - 0.896 confidence ❌
4. **Colosseum (height: NULL)** - 0.878 confidence ❌
5. **Big Ben (height: NULL)** - 0.872 confidence ❌
6. **Lake Geneva (height: NULL)** - 0.866 confidence ❌
7. **Acropolis (height: NULL)** - 0.860 confidence ❌
... (18 total candidates - NOT filtered!)

**Problem:** Most places return `height='NULL'` - the filter isn't eliminating them.

**Why:** 
- Most places don't have `descriptors->>'height_meters'` 
- Some have `descriptors->'extratags'->>'height'`
- Missing data defaults to 0 or NULL, which fails the `>= 200` check differently

**Result:** ❌ **BROKEN** - Height filter has zero effect!

---

## Implementation Issues Found

### Bug #1: Property Extraction Too Simple (Line 41)

**Current Code:**
```sql
actual_value := descriptors->property;
```

**Problem:**
- Only checks top-level properties
- Doesn't handle nested paths like `extratags->>'height'`
- Doesn't handle proper type coercion (-> vs ->>)

**Example:**
```json
{
  "height_meters": 330,           // ✓ Found
  "extratags": {
    "height": "330"                // ✗ NOT found
  }
}
```

**Fix Needed:**
```sql
-- For numeric checks, try multiple paths with fallback
IF filter_type = 'numeric_check' THEN
  actual_value := COALESCE(
    (descriptors->>property)::float,
    (descriptors->'extratags'->>property)::float,
    0  -- Default for missing
  );
END IF;
```

---

### Bug #2: NULL Handling Missing (Line 52)

**Current Code:**
```sql
IF operator = '>=' THEN
  result := actual_value::float >= value::float;  -- Crashes on NULL
```

**Problem:** 
- When `height_meters` is NULL, conversion to float fails
- Or worse, NULL passes the filter incorrectly

**Fix Needed:**
```sql
IF operator = '>=' THEN
  result := COALESCE(actual_value::float, 0) >= (value::text)::float;
```

---

### Bug #3: Type Check Operator Wrong (Line 46)

**Current Code:**
```sql
IF operator = 'in' THEN
  result := actual_value <@ value;  -- ❌ Wrong JSONB operator
```

**Problem:**
- `<@` checks if left JSONB is contained in right JSONB
- `descriptors->>'type'` returns TEXT "tower", not JSONB
- Need to check if TEXT value is in JSONB array

**Fix Needed:**
```sql
IF operator = 'in' THEN
  -- Convert text to jsonb for comparison, or use ANY
  result := to_jsonb((descriptors->>property)::text) <@ value;
  -- OR simpler:
  result := (descriptors->>property) = ANY(
    SELECT jsonb_array_elements_text(value)
  );
```

**Note:** This bug didn't show in Test 1 because it worked by accident. May fail with different data structures.

---

### Bug #4: Question Text Matching Risk (Lines 11-21)

**Current Code:**
```sql
UPDATE questions
SET metadata_filter = '{ ... }'
WHERE text = 'Is it a bridge or tower?';  -- Must match exactly
```

**Risk:** 
- If question text has trailing spaces, different punctuation, or was edited, UPDATE won't match
- Silent failure - no error, just filter not applied

**Better Approach:**
```sql
UPDATE questions
SET metadata_filter = '{ ... }'
WHERE id = 'uuid-here';  -- Match by ID instead
```

---

## What Works vs What's Broken

### ✅ Works Well

1. **Architecture** - Dynamic metadata filter system is extensible and clean
2. **Type filtering** - Successfully filters by `type` field (bridge, tower)
3. **CTE placement** - Correct position in pipeline (after geographic, before semantic boost)
4. **Ceiling fix** - Changed from 1.0 to 0.95 prevents score collapse
5. **Semantic boost reduction** - 0.3 → 0.1 multiplier preserves differentiation
6. **Helper function design** - Centralized logic is maintainable

### ❌ Broken

1. **Height filtering** - Completely non-functional, all candidates pass
2. **Property extraction** - Can't access nested properties (extratags)
3. **NULL handling** - Missing data causes wrong results
4. **Data coverage** - Most places lack height_meters field
5. **Type check operator** - May fail on certain data structures

---

## Overall Assessment

**Score: 6/10**

**Strengths:**
- ✅ Excellent architectural approach
- ✅ Bridge/tower filter works perfectly
- ✅ Solves the core "soft adjustment" problem
- ✅ Extensible system for future questions

**Weaknesses:**
- ❌ Height filter completely broken
- ❌ Implementation bugs in property access
- ❌ Missing data coverage (most places lack height)
- ❌ No fallback logic for nested properties

**Recommendation:**
Fix the `apply_metadata_filter()` function to:
1. Handle nested property paths (descriptors->extratags->height)
2. Add proper NULL handling with defaults
3. Fix type check operator for reliable array matching
4. Consider adding fallback properties (height OR ele for elevation)

**Next Steps:**
1. Fix property extraction to check multiple paths
2. Add NULL coalescing with sensible defaults
3. Test with more questions (natural feature, capital city)
4. Verify type check operator works with all data structures

---

## Code Locations

- **Migration file:** `supabase/migrations/000004_refactor_get_candidates.sql`
- **Helper function:** Lines 24-73 (`apply_metadata_filter`)
- **Updated get_candidates:** Lines 76-294
- **Question updates:** Lines 11-21
- **Metadata filtering CTE:** Lines 191-200

---

## Test Data

**Working Filter Example:**
```sql
-- Type check: Bridge or tower
metadata_filter: {
  "type": "type_check",
  "property": "type",
  "operator": "in",
  "value": ["bridge", "tower"]
}
-- Result: ✅ Filtered 5 → 1 candidate correctly
```

**Broken Filter Example:**
```sql
-- Height check: Over 200 meters
metadata_filter: {
  "type": "numeric_check",
  "property": "height_meters",
  "operator": ">=",
  "value": 200
}
-- Result: ❌ No filtering effect (18 candidates remain)
```

---

## Related Memories

- `test-findings-automated-game-session` - Original test that identified the algorithm issue
- `game-vector-system` - Context about the embedding system
- `game-question-system` - Question structure and types
