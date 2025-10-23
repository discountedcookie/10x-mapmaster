# MapMaster Test Findings - Automated Game Session

**Test Date:** 2025-10-23  
**Test Type:** Automated agent playthrough using Supabase MCP tools  
**Session ID:** `358f45f4-a793-4f83-bf6d-5bacceff4bac`

## Test Scenario

**Description:** "Tall iron tower in Paris France"  
**Target Place:** Eiffel Tower  
**Expected Behavior:** System should rank Eiffel Tower #1 throughout, make correct guess after 1-2 questions  
**Actual Result:** ✅ Correct guess made, but ❌ ranking logic severely broken

---

## Key Findings

### 1. ✅ Embeddings Work Excellently

**Initial ranking (before any questions):**
1. **Eiffel Tower** - 0.885 confidence (CORRECT)
2. Tower Bridge - 0.826 confidence
3. Burj Khalifa - 0.822 confidence
4. Colosseum - 0.806 confidence
5. Big Ben - 0.801 confidence

The GTE-small (384-dim) embedding correctly understood:
- "Tall" → height semantics
- "Iron tower" → metal construction, tower structure
- "Paris France" → geographic location

**Conclusion:** The vector embeddings are doing their job correctly. Initial semantic matching is accurate.

---

### 2. ❌ Algorithm Breaks After Questions

**After Question 1: "Is it a bridge or tower?" (answered YES)**

Candidate ranking changed to:
1. **Acropolis** (ancient fortress) - 0.997 confidence ❌
2. **Colosseum** (amphitheater) - 0.996 confidence ❌
3. **Sagrada Familia** (basilica) - 0.994 confidence ❌
4. **Lake Geneva** (lake!) - 0.994 confidence ❌
5. **Eiffel Tower** (tower) - 0.992 confidence ✓

**Critical Issues:**
- ALL candidates got `semantic_similarity = 1.0`
- Wrong place types (castle, amphitheater, lake, basilica) NOT filtered out
- Only actual tower dropped to #5
- Spatial clustering dominated ranking after semantic scores hit ceiling

**After Question 2: "Is it very tall (over 200 meters)?" (answered YES)**

Ranking remained unchanged:
- Acropolis (156m elevation) still #1 ❌
- Lake Geneva (no meaningful height) still in top 5 ❌
- No filtering effect whatsoever

---

### 3. 🔍 Root Cause: Soft Adjustment Instead of Hard Filtering

**Location:** `supabase/migrations/000003_database_functions.sql`, lines 219-257

**Current Approach (BROKEN):**
```sql
semantic_boost = AVG(
  IF answer=YES: +(1 - place_emb <=> question_emb)
  IF answer=NO:  -(1 - place_emb <=> question_emb)
)
adjusted_similarity = LEAST(1.0, original_sim + boost * 0.3)
```

**Why This Fails:**
1. **Doesn't eliminate wrong types** - Lake Geneva answered "Is it a tower?" YES because its embedding is somewhat similar to tower concepts (landmarks, attractions)
2. **Ceiling effect** - Most candidates hit 1.0 semantic similarity after boost
3. **Spatial dominance** - Once semantic=1.0 for all, ranking = pure geographic clustering
4. **Ignores structured metadata** - Has `descriptors->>'type'` but doesn't use it

**Example Failure:**
- Lake Geneva initial: 0.789 similarity
- Question embedding similarity: ~0.4 (both are landmarks)
- Boost: +0.4 * 0.3 = +0.12
- Result: 0.789 + 0.12 = 0.909 (survives filter!)
- Should: ELIMINATED (type='lake', not 'tower')

---

### 4. 📚 Historical Context: Deprecated Function Worked Better

**Location:** Lines 460-616, function `filter_candidates_with_history`

**Old Approach (CORRECT):**
```sql
-- Bridge or tower filtering (line 563-571)
IF question_text = 'Is it a bridge or tower?' THEN
  DELETE FROM filtered_candidates fc
  WHERE NOT (
    (user_answer = TRUE AND (fc.descriptors->>'type' = 'bridge' OR fc.descriptors->>'type' = 'tower'))
    OR
    (user_answer = FALSE AND fc.descriptors->>'type' != 'bridge' AND fc.descriptors->>'type' != 'tower')
  );
END IF;
```

This function had explicit hardcoded filters for:
- Natural features (line 530-538)
- Major city (line 541-548)
- Capital city (line 552-560)
- Bridge or tower (line 563-571)

**Evolution:**
1. v1: Hardcoded metadata filtering ✓ Worked correctly
2. v2: "Pure embedding" approach ❌ Lost accuracy
3. Reason for change: Likely wanted more flexibility/scalability
4. Result: Traded accuracy for generality

---

### 5. 🎯 Metadata vs Embeddings: Wrong Tool for the Job

**What Embeddings Are Good At:**
- ✅ Semantic understanding ("tall iron tower" → Eiffel Tower concept)
- ✅ Handling natural language variety
- ✅ Initial candidate ranking
- ✅ Finding contextually relevant questions

**What Embeddings Are Bad At:**
- ❌ Boolean factual filtering (is it a tower? yes/no)
- ❌ Numeric comparisons (height > 200m)
- ❌ Type checking (type='tower' vs type='lake')
- ❌ Precise attribute matching

**What Metadata Is Good At:**
- ✅ Exact type matching (`descriptors->>'type'`)
- ✅ Height comparisons (`descriptors->>'height_meters' > 200`)
- ✅ Boolean flags (`descriptors->>'is_capital_city'`)
- ✅ Geographic boundaries (already working via PostGIS)

**Current Problem:** Algorithm uses embeddings for both, when it should use hybrid approach.

---

### 6. 📊 Specific Algorithm Issues

#### Issue A: Semantic Similarity Ceiling (Line 267)
```sql
GREATEST(0.0, LEAST(1.0, sa.sem_similarity + (sa.semantic_boost * 0.3))) as sem_similarity
```
- Allows boosts up to +0.3 (after multiplier)
- Multiple candidates hit 1.0 ceiling
- Destroys differentiation between candidates

#### Issue B: Composite Confidence Formula (Line 301)
```sql
(c.sem_similarity * 0.95 + spatial_confidence * 0.05) AS composite_confidence
```
- With semantic=1.0 for all, formula becomes: `0.95 + spatial * 0.05`
- Spatial confidence (0.85-0.93) creates only 0.004 score difference
- Geographic clustering dominates, not semantic correctness

#### Issue C: Missing Height Filter
No logic for "Is it very tall (over 200 meters)?" question:
- Should check: `descriptors->>'height_meters'::float >= 200`
- Currently: Only adjusts score via embedding similarity
- Result: 156m Acropolis survives "over 200m" filter

#### Issue D: Missing Type Filter  
No logic for "Is it a bridge or tower?" question after line 218:
- Should check: `descriptors->>'type' IN ('bridge', 'tower')`
- Currently: Only adjusts score via embedding similarity
- Result: Lake, castle, amphitheater survive tower filter

---

## 🔧 Recommended Fixes

### Fix 1: Add Metadata-Based Filtering Phase
Insert after `geographic_filtered_candidates` (line 218):

```sql
metadata_filtered_candidates AS (
  SELECT *
  FROM geographic_filtered_candidates gfc
  WHERE 
    -- Bridge or tower hard filter
    NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
      WHERE q.value->>'question' = 'Is it a bridge or tower?'
        AND (q.value->>'answer')::boolean = true
        AND gfc.descriptors->>'type' NOT IN ('bridge', 'tower')
    )
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
      WHERE q.value->>'question' = 'Is it a bridge or tower?'
        AND (q.value->>'answer')::boolean = false
        AND gfc.descriptors->>'type' IN ('bridge', 'tower')
    )
    -- Height hard filter
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
      WHERE q.value->>'question' = 'Is it very tall (over 200 meters)?'
        AND (q.value->>'answer')::boolean = true
        AND COALESCE(
          (gfc.descriptors->>'height_meters')::float,
          (gfc.descriptors->'extratags'->>'height')::float,
          0
        ) < 200
    )
    -- Natural feature hard filter
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
      WHERE q.value->>'question' = 'Is it a natural feature?'
        AND (q.value->>'answer')::boolean = true
        AND gfc.descriptors->>'class' != 'natural'
    )
    -- Add more filters as needed...
)
```

### Fix 2: Reduce Semantic Boost Ceiling
Change line 267:
```sql
-- Old: allows +0.3 boost, hits ceiling easily
GREATEST(0.0, LEAST(1.0, sa.sem_similarity + (sa.semantic_boost * 0.3)))

-- New: allows +0.1 boost, preserves differentiation
GREATEST(0.1, LEAST(0.95, sa.sem_similarity + (sa.semantic_boost * 0.1)))
```

### Fix 3: Use Semantic Boost as Tiebreaker Only
Apply embedding-based adjustment only to candidates that pass metadata filters, not as primary filtering mechanism.

---

## 📈 Test Statistics

- **Questions asked:** 2/5
- **Wrong guesses:** 0
- **Agent decision:** Correct (identified Eiffel Tower despite ranking)
- **System ranking:** Incorrect (ranked Eiffel Tower #5 after questions)
- **Initial candidates:** 10 places
- **Final candidates:** 5 places (but wrong ones ranked higher)
- **Embedding accuracy:** 9/10 (excellent initial ranking)
- **Algorithm accuracy:** 3/10 (broken post-question filtering)

---

## 🎯 Conclusion

**Embeddings: ✅ Working correctly**
- Initial semantic matching is accurate
- GTE-small model understands descriptions well
- No need to change embedding model or dimensions

**Algorithm: ❌ Fundamentally broken**
- Semantic questions don't filter, only adjust scores
- Metadata exists but isn't used for filtering
- Ceiling effect destroys candidate differentiation
- Spatial clustering dominates after semantic scores collapse

**Solution: Hybrid approach needed**
- Use embeddings for initial semantic ranking
- Use metadata for hard filtering on factual questions
- Use embedding boost only as tiebreaker for remaining candidates
- Trust structured data over fuzzy embedding similarities

**Priority: HIGH** - This directly impacts gameplay accuracy and user experience.

---

## Related Files

- `supabase/migrations/000003_database_functions.sql` - Main filtering logic
  - Lines 106-312: `get_candidates()` function (broken)
  - Lines 460-616: `filter_candidates_with_history()` function (deprecated, worked better)
- Test session: `358f45f4-a793-4f83-bf6d-5bacceff4bac`
- Test user: `e5335fd5-348d-4047-9a9e-241e49bc01b8`
