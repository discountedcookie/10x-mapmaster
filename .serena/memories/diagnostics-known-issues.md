# Diagnostics: Known Issues

## Database Reset and Embeddings

**Issue:** After running `npx supabase db reset`, places and questions will have NULL embeddings and NULL geom fields.

**Why:** Migrations create schema and seed basic data, but embeddings require production Edge Function.

**Solution:** You must run the seed scripts to generate this data:
```bash
npm run seed:places
npm run seed:questions
```

**Important:** Only user can run seed scripts (require production env variables).

---

## E2E Tests Disabled in CI

**Issue:** Playwright E2E tests pass locally but are flaky in CI environment.

**Status:** Job commented out in `.github/workflows/ci.yml` (lines 94-147).

**Workaround:** Run E2E tests locally only:
```bash
npm run test:e2e
```

**Can be re-enabled:** When CI environment stabilizes.

---

## Semantic Filtering Bug (RESOLVED - October 23, 2025)

### Problem
User describes "One of the tallest mountains" thinking of Mount Fuji. After rejecting Mount Everest by answering NO to semantic questions, game shows "0 places remaining".

### Root Cause
**ALL 14 semantic questions were non-discriminative** - every place had similarity >= 0.734 to every question:

| Question | Min Sim | Max Sim | Result |
|----------|---------|---------|---------|
| Is it in a major city? | 0.774 | 0.834 | ALL match |
| Is it near river/lake? | 0.767 | 0.848 | ALL match |
| Is it near ocean/sea? | 0.766 | 0.798 | ALL match |
| Is it very tall? | 0.738 | 0.785 | ALL match |

When user answers NO to any semantic question, ALL places are excluded because they all match (similarity > 0.4).

### Why This Happened
Place embeddings generated from minimal text:
```
"Mount Fuji. Type: peak. Category: natural. Country: Japan"
"Mount Everest. Type: peak. Category: natural. Country: Nepal"
```

Both are "peak + natural + country" → nearly identical embeddings → no discrimination.

**The gte-small model (384 dimensions) is NOT the problem.** The issue was input text quality, not model capacity.

### Emergency Fix Applied
Migration 000010: Disabled all semantic questions (set `is_active = false`)
- Game now uses ONLY geographic questions (continents, hemispheres, regions)
- Geographic questions work correctly with PostGIS spatial queries

### Long-Term Solution (Future Work)
**Option 1: Enrich Place Embedding Input Text (RECOMMENDED)**

Use Nominatim extratags + Wikipedia descriptions:

**Current:** "Mount Fuji. Type: peak. Category: natural. Country: Japan"

**Improved:** "Mount Fuji. Type: peak. Elevation: 3776 meters. Natural feature: volcano. Active stratovolcano, Japan's tallest mountain. Sacred site in Japanese culture. Country: Japan"

**Option 2: Manual Height/Characteristics in Seed Data**

Add structured data manually to `000002_seed_data.sql`:
```sql
INSERT INTO places (name, lat, lng, descriptors) VALUES
  ('Mount Fuji', 35.3606, 138.7274, '{
    "type":"peak",
    "class":"natural",
    "country_code":"jp",
    "continent":"asia",
    "height_meters": 3776,
    "natural_type": "volcano",
    "is_active_volcano": true
  }'::jsonb)
```

**Key Insight:** Semantic similarity models are designed to recognize that "Mount Fuji" and "Mount Everest" ARE semantically similar (both are tall natural mountains). The only way to discriminate them is to add distinguishing features in the input text (height: 3776m vs 8849m).

---

## PostgreSQL UUID Aggregation

**Issue:** `MIN(id)` doesn't work on UUID type.

**Error:**
```sql
SELECT COUNT(*), MIN(id) INTO candidate_count, remaining_place
FROM get_candidates(test_session_id);
-- ERROR: function min(uuid) does not exist
```

**Solution:** Separate queries:
```sql
SELECT COUNT(*) INTO candidate_count FROM get_candidates(test_session_id);
SELECT id INTO remaining_place FROM get_candidates(test_session_id) LIMIT 1;
```

---

## Type Instantiation Too Deep

**Issue:** Vue reactive types causing infinite type recursion.

**Error:** `TS2589: Type instantiation is excessively deep and possibly infinite`

**Location:** `src/stores/game.ts` when working with deeply nested reactive objects.

**Solution:** Strip reactivity with `toRaw()`:
```typescript
import { toRaw } from 'vue'
const currentCandidates = toRaw(candidates.value)
const candidatePlaceIds = currentCandidates.map((c: any) => c.id)
```

**Why:** Vue's reactive proxy types can become deeply nested, especially with arrays of objects. Using `toRaw()` extracts the underlying data without reactivity.

---

## Null Safety Issues

**Issue:** Component crashes when place coordinates are null.

**Example:**
```typescript
// ❌ Crashes if lat is null
{{ guess.lat.toFixed(4) }}°

// ❌ Type error when filtering
return gameStore.topCandidates.map(place => ({ lat: place.lat, lng: place.lng }))
```

**Solution:** Use optional chaining and null filters:
```typescript
// ✅ Safe
{{ guess.lat?.toFixed(4) ?? 'N/A' }}°, {{ guess.lng?.toFixed(4) ?? 'N/A' }}°

// ✅ Filter null coordinates
return gameStore.topCandidates
  .filter(place => place.lat !== null && place.lng !== null)
  .map(place => ({ lat: place.lat!, lng: place.lng!, ... }))
```

---

## SQL Syntax Error in pgTAP

**Issue:** `RETURNING INTO` is invalid in pgTAP context.

**Error:**
```sql
INSERT INTO game_sessions (user_id, description)
VALUES (test_user_id, 'description')
RETURNING id INTO test_session_id; -- ERROR
```

**Solution:** Use CTE pattern:
```sql
WITH new_session AS (
  INSERT INTO game_sessions (user_id, description, description_embedding)
  SELECT user_id, 'description', test_dummy_embedding(1)
  FROM test_data
  RETURNING id
)
UPDATE test_data SET session_id = (SELECT id FROM new_session);
```

---

## Cosine Similarity Test Data

**Issue:** All test places have identical similarity scores, making tests fail.

**Why:** Vectors `[0.1, 0.1, ...]` and `[0.2, 0.2, ...]` point in the SAME direction → identical cosine similarity (1.0).

**Key Learning:** Cosine similarity measures DIRECTION not MAGNITUDE. Need embeddings pointing in different directions.

**Solution:** Create test places with distinct embedding patterns:
```sql
CREATE OR REPLACE FUNCTION test_dummy_embedding(pattern_id int DEFAULT 1)
RETURNS vector(384) AS $$
  SELECT (
    CASE 
      WHEN pattern_id = 1 THEN array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[383])
      WHEN pattern_id = 2 THEN array_fill(0.1::float, ARRAY[1]) || array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[382])
      WHEN pattern_id = 3 THEN array_fill(0.1::float, ARRAY[2]) || array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[381])
      ELSE array_fill(0.1::float, ARRAY[384])
    END
  )::vector(384);
$$ LANGUAGE sql;
```

Each place gets a unique pattern (different "direction" in vector space), making them distinguishable by cosine similarity.

---

## Database Types Out of Sync

**Issue:** Migration schema changes not reflected in TypeScript types.

**Symptoms:**
- Type errors referencing old schema
- Missing fields in TypeScript types
- Wrong types for database columns

**Solution:** Regenerate types after schema changes:
```bash
npm run supabase:types
```

**When to regenerate:**
- After creating new migration
- After modifying existing migration during development
- After pulling schema changes from remote
- Before committing schema changes

---

## Question Effectiveness Learning Bug (FIXED)

**Issue:** ALL effectiveness scores were decreasing, even for good questions.

**Problem:** Original formula divided by 2.0:
```sql
-- BROKEN
effectiveness_score = (effectiveness_score + effectiveness_delta) / 2.0
-- Result: 0.5 + 0.1 = 0.6 / 2.0 = 0.3 (decreased!)
```

**Fix:** Use proper learning rate:
```sql
-- FIXED - learning rate of 0.2
effectiveness_score = LEAST(1.0, GREATEST(0.0, 
  effectiveness_score + 0.2 * effectiveness_delta
))
```

**Additional Fix:** Handle NULL `candidates_before` (first question):
```sql
IF answer_record.candidates_before IS NULL THEN
  initial_candidate_count := 20;
ELSE
  initial_candidate_count := jsonb_array_length(
    answer_record.candidates_before->'place_ids'
  );
END IF;
```

---

## Map Blinking on Route Change (FIXED)

**Issue:** Map was recreating when navigating between HomeView and GameView.

**Root Cause:** Each view had its own `<MapView>` component that was unmounted/mounted on route change.

**Solution:** Create shared `MapLayout.vue` that wraps both views with single persistent map instance.

**See:** `design-architecture.md` for full implementation details.

---

## Theme Not Persisting (FIXED)

**Issue:** Theme preference wasn't persisting to localStorage, and map styles weren't switching when theme changed.

**Root Causes:**
1. `useColorMode` returns resolved theme (light/dark), not user preference (light/dark/auto)
2. MapLibre component doesn't react to `:map-style` prop changes
3. No separation between user preference and resolved theme

**Solution:** Custom theme composable with dual state management + Vue `key` attribute on map.

**See:** `design-architecture.md` for full implementation details.

---

## Common Gotchas

### 1. Embedding Generation Requires Production Edge Function
Local development calls production Edge Function for embeddings. No local embedding generation.

### 2. Seed Scripts Need Env Variables
Agent cannot run seed scripts - they require production environment variables.

### 3. Database Tests Don't Need Seed Data
pgTAP tests are self-contained with transaction ROLLBACK. Don't depend on enriched seed data.

### 4. Vector Indexes Take Time
HNSW indexes on large datasets take time to build. Expect delays on first migration.

### 5. RLS Policies Apply to Service Role
Even with service role key, RLS policies apply unless explicitly bypassed with `SECURITY DEFINER`.

### 6. MapLibre Lazy Loading
MapLibre is ~500KB. Always lazy load:
```typescript
const maplibregl = await import('maplibre-gl')
```

### 7. Supabase Client Singleton
Create Supabase client once, export as singleton. Don't create multiple instances.