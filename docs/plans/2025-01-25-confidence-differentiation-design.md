# Confidence Differentiation Design

**Date:** 2025-01-25
**Status:** Approved for Implementation
**Priority:** Blocking 1.0.0 Release

## Problem Statement

Current confidence scores shown to users cluster around 80%/70% for all top candidates, making it difficult to distinguish between likely and unlikely matches.

**Root Cause:** Raw `composite_confidence` values from database are naturally clustered (0.78, 0.76, 0.74...) due to cosine similarity behavior on embeddings.

## Solution: Percentile Ranking Normalization

Apply percentile ranking transformation in the frontend to amplify small differences in semantic similarity scores.

### Architecture

**Two-tier confidence system:**
- **Database Layer:** Returns raw `composite_confidence` (0-1 range, semantic truth)
- **Frontend Layer:** Applies percentile normalization for display (15-95% range)

**Separation of Concerns:**
- Raw scores used for game logic, database updates, learning
- Normalized scores used only for user-facing display

### Implementation

#### Frontend Changes (`src/stores/game.ts`)

**Add normalization function:**
```typescript
function normalizeConfidencePercentile(
  candidates: PlaceWithScore[]
): PlaceWithScore[] {
  if (candidates.length === 0) return []
  if (candidates.length === 1) return [{...candidates[0], composite_confidence: 0.95}]

  return candidates.map((candidate, index) => {
    const rank = index + 1
    const total = candidates.length
    // Linear interpolation: 95% for rank 1, 15% for rank N
    const normalizedConfidence = 0.95 - ((rank - 1) / (total - 1)) * 0.80

    return {
      ...candidate,
      composite_confidence: normalizedConfidence
    }
  })
}
```

**Add computed property:**
```typescript
const normalizedTopCandidates = computed(() =>
  normalizeConfidencePercentile(topCandidates.value)
)
```

**Update GameView.vue (line 330):**
Change from `gameStore.topCandidates` to `gameStore.normalizedTopCandidates`

### Data Flow

```
Database (get_candidates)
  → composite_confidence: 0.78, 0.76, 0.74, 0.72, 0.70
  → Game Store
    → topCandidates (raw: 0.78, 0.76, 0.74...)
    → normalizedTopCandidates (display: 95%, 75%, 55%, 35%, 15%)
  → UI Components (QuestionCard, ResultCard)
```

### Expected Results

**Example spreads:**
- 5 candidates: 95%, 75%, 55%, 35%, 15%
- 10 candidates: 95%, 86%, 77%, 69%, 60%, 51%, 42%, 33%, 24%, 15%
- 3 candidates: 95%, 55%, 15%

**Badge distribution:**
- High (≥80%, green): Only top 1-2 candidates
- Medium (50-80%, yellow): Middle candidates
- Low (<50%, gray): Bottom candidates

### Edge Cases

1. **Empty candidates** → Return empty array
2. **Single candidate** → Always 95%
3. **Two candidates** → Maximum spread (95%, 15%)
4. **After filtering** → Re-normalize remaining candidates
5. **Very similar raw scores** → Still get spread (intentional amplification)

## Testing Strategy

### Database Tests (`supabase/tests/test_confidence_scores.sql`)

**Goal:** Verify raw scores and document clustering behavior

1. **Clustered scores test:** Insert similar places, verify `composite_confidence` values are close
2. **Sorting test:** Verify results ordered by `composite_confidence DESC`
3. **Filtering preservation:** After answering questions, raw scores unchanged
4. **Documentation:** Capture actual clustering numbers as evidence for normalization need

### Frontend Unit Tests (Future)

`src/stores/__tests__/game-normalization.spec.ts` - Test normalization function edge cases

### E2E Tests (Future)

`e2e/confidence-display.spec.ts` - Verify UI shows differentiated badges

## Manual Verification

```sql
SELECT name, semantic_similarity, composite_confidence
FROM get_candidates('session-id')
ORDER BY composite_confidence DESC
LIMIT 10;
```

## Notes

- **Database unchanged:** No migration needed, all changes in frontend
- **Backward compatible:** Can toggle normalization on/off via feature flag if needed
- **Production database:** Test carefully with production data (has embeddings), don't delete data
- **Embedding generation:** Use edge function for test descriptions, save to temp table (don't load 384 dimensions into context)

## Impact on 1.0.0 Release

**Unblocks:** Primary UX concern preventing release
**User benefit:** Clear visual differentiation between likely/unlikely candidates
**Risk:** Low - frontend-only change, no database migration
