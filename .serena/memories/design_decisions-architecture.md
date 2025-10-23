## Session-First Architecture (October 22, 2025)

**Core Concept**: Database is source of truth. Game session created immediately, all state derived from relations.

**Schema Changes** (`000001_initial_schema.sql`):
- `game_answers` table refactored with `answer_type` enum, place_id for wrong guesses
- `game_sessions` simplified (nullable place_id, was_correct)
- `game_session_stats` view for computed statistics

**Database Functions** (`000003_database_functions.sql`):
1. `get_candidates(session_id)` - Session-aware candidate retrieval
2. `update_question_effectiveness_batch(session_id)` - Batch learning

**Game Store**: Fully database-centric with session tracking

**Wikipedia Enrichment**: Integrated for richer place embeddings

**Testing**: 11 comprehensive tests (pgTAP) all passing

---

## Algorithmic Filtering Architecture (October 23, 2025)

**Decision:** Remove all hardcoded question filters, implement pure algorithmic approach using pgvector + PostGIS only

**Context:**
- Original system had 40+ lines of hardcoded CASE WHEN statements
- Explicit field checks: `descriptors->>'class' = 'natural'`, `descriptors->>'is_capital_city'`
- String matching for routing: `q.value->>'question' = 'Is it in a capital city?'`
- Silent failures when fields missing (ELSE TRUE fallback)
- Required code changes + deployment to add new questions

**New Architecture - Two Pure Filters:**

1. **Geographic Filtering** - PostGIS bbox intersection (ST_Within)
   - YES answers: candidate must be WITHIN bbox
   - NO answers: candidate must be OUTSIDE bbox
   - No hardcoded country/region checks

2. **Semantic Filtering** - pgvector cosine similarity
   - Calculate similarity between place and answered questions
   - YES answers: boost confidence by similarity score
   - NO answers: penalize confidence by similarity score
   - Boost weight: 0.3 (adjustable)

**Implementation:**
```sql
-- Geographic: Pure spatial operations
WHERE NOT EXISTS (
  SELECT 1 FROM answered_geographic
  WHERE (answer = YES AND NOT ST_Within(place, bbox))
     OR (answer = NO AND ST_Within(place, bbox))
)

-- Semantic: Pure vector similarity
semantic_boost = AVG(
  CASE 
    WHEN answer = YES THEN (1 - place_emb <=> question_emb)
    ELSE -(1 - place_emb <=> question_emb)
  END
) * 0.3
```

**Test Results:**
- Mount Fuji: Guessed immediately (83% confidence) ✅
- Machu Picchu: 2 questions, 15→2 candidates (87% reduction) ✅
- Geographic filtering: Perfect bbox intersection ✅
- Semantic adjustment: Confidence boost/penalty working ✅

**Benefits:**
- ✅ Zero hardcoded filters
- ✅ Adding questions = INSERT only (no code changes)
- ✅ Scales to infinite questions
- ✅ Geographic questions now visible (0.6 baseline score)
- ✅ No silent failures
- ✅ Pure ML/AI system

**Trade-offs:**
- Requires good place embeddings (future: rich enrichment)
- Semantic matching depends on embedding quality
- Slightly more complex SQL (but more maintainable)

**Files Modified:**
- `supabase/migrations/000003_database_functions.sql` (lines 178-262, 403, 314-321)

**Rationale:**
System should learn from embeddings, not hardcoded rules. Questions are data, not code. Future enrichment will add context like "Eiffel Tower in Paris, capital of France" so questions like "capital city" work naturally via semantic similarity.

---

## Per-Place Spatial Confidence (October 22, 2025)

**Implementation:** Calculate spatial confidence individually per place based on distance from candidate set centroid

**Formula:** `1 - (distance_to_centroid / max_distance)`

**Already Implemented:** Lines 263-282 in `000003_database_functions.sql`
