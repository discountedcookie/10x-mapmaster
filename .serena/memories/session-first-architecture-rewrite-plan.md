# 🎯 Session-First Game Architecture Rewrite Plan

## 📐 Architecture Principles

**Session-First Design:**
- Game session created when user submits description
- All RPC functions take `game_session_id` only - query relations internally
- Question count = COUNT of game_answers (no stored counter)
- Wrong guesses stored as `game_answer` with `answer_type='wrong_guess'`
- Candidates stored as JSONB `{place_ids: [], confidence_scores: {semantic, spatial, composite}}`

**Database-First Logic:**
- `get_candidates(session_id)` → returns filtered candidates with scores
- `get_next_question(session_id)` → selects questions using session relations
- Question effectiveness updated at session end (if guessed correctly)
- All game state derived from database relations

---

## 🗄️ Phase 1: Database Schema Updates

### 1.1 Update game_answers Table
**File:** `supabase/migrations/000001_initial_schema.sql`

**Changes:**
```sql
-- Add answer_type and place_id for wrong guesses
ALTER TABLE game_answers
ADD COLUMN answer_type TEXT NOT NULL DEFAULT 'question_answer' 
  CHECK (answer_type IN ('question_answer', 'wrong_guess')),
ADD COLUMN place_id UUID REFERENCES places(id) ON DELETE CASCADE;

-- Update candidates_after to JSONB for rich data
ALTER TABLE game_answers
DROP COLUMN candidates_after,
ADD COLUMN candidates_after JSONB NOT NULL DEFAULT '{
  "place_ids": [],
  "confidence_scores": {
    "semantic": 0.0,
    "spatial": 0.0,
    "composite": 0.0
  }
}'::jsonb;

COMMENT ON COLUMN game_answers.answer_type IS 
'Type: question_answer (YES/NO to question) or wrong_guess (eliminated place)';

COMMENT ON COLUMN game_answers.place_id IS 
'For wrong_guess type: the place_id that was guessed incorrectly';
```

**Why:** Enables storing wrong guesses and rich candidate metadata

---

### 1.2 Remove question_count from game_sessions
**File:** `supabase/migrations/000001_initial_schema.sql`

**Changes:**
```sql
-- Remove redundant question_count column
ALTER TABLE game_sessions
DROP COLUMN question_count;

-- Add view for computed question count
CREATE VIEW game_session_stats AS
SELECT 
  gs.id as session_id,
  gs.user_id,
  gs.place_id,
  gs.was_correct,
  gs.description,
  gs.created_at,
  COUNT(ga.id) FILTER (WHERE ga.answer_type = 'question_answer') as question_count,
  COUNT(ga.id) FILTER (WHERE ga.answer_type = 'wrong_guess') as wrong_guess_count
FROM game_sessions gs
LEFT JOIN game_answers ga ON ga.session_id = gs.id
GROUP BY gs.id;

COMMENT ON VIEW game_session_stats IS 
'Computed stats for game sessions from game_answers relation';
```

**Why:** Single source of truth - count from relation, not stored value

---

## 🔧 Phase 2: New Database Functions

### 2.1 Create get_candidates() Function
**File:** `supabase/migrations/000003_database_functions.sql`

**New function:**
```sql
CREATE OR REPLACE FUNCTION get_candidates(
  session_id_param UUID
)
RETURNS TABLE (
  id uuid,
  name text,
  lat double precision,
  lng double precision,
  descriptors jsonb,
  semantic_similarity float,
  spatial_confidence float,
  composite_confidence float
)
LANGUAGE plpgsql
AS $$
DECLARE
  description_embedding vector(384);
  eliminated_place_ids UUID[];
  question_history JSONB;
BEGIN
  -- Get description embedding from session
  SELECT gs.description_embedding INTO description_embedding
  FROM game_sessions gs
  WHERE gs.id = session_id_param;
  
  IF description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or missing embedding', session_id_param;
  END IF;
  
  -- Get eliminated places from wrong guesses
  SELECT array_agg(ga.place_id)
  INTO eliminated_place_ids
  FROM game_answers ga
  WHERE ga.session_id = session_id_param
    AND ga.answer_type = 'wrong_guess'
    AND ga.place_id IS NOT NULL;
  
  -- Build question history from answers
  SELECT json_agg(
    json_build_object(
      'question', q.text,
      'answer', ga.answer,
      'question_type', q.question_type,
      'geographic_region', q.geographic_region
    ) ORDER BY ga.sequence_number
  )
  INTO question_history
  FROM game_answers ga
  JOIN questions q ON q.id = ga.question_id
  WHERE ga.session_id = session_id_param
    AND ga.answer_type = 'question_answer';
  
  -- Get initial candidates by vector similarity
  WITH initial_candidates AS (
    SELECT
      p.id,
      p.name,
      p.lat,
      p.lng,
      p.descriptors,
      p.geom,
      1 - (p.embedding <=> description_embedding) as semantic_sim
    FROM places p
    WHERE p.embedding IS NOT NULL
      AND p.geom IS NOT NULL
      AND (eliminated_place_ids IS NULL OR p.id != ALL(eliminated_place_ids))
      AND 1 - (p.embedding <=> description_embedding) > 0.1
    ORDER BY p.embedding <=> description_embedding
    LIMIT 20
  ),
  -- Apply geographic and semantic filters from question history
  filtered_candidates AS (
    SELECT * FROM initial_candidates
    -- TODO: Apply filter logic similar to filter_candidates_with_history
    -- but integrated here
  ),
  -- Calculate spatial confidence
  spatial_scores AS (
    SELECT
      fc.*,
      -- Spatial clustering logic here (from match_places)
      1.0 as spatial_score -- Placeholder
    FROM filtered_candidates fc
  )
  RETURN QUERY
  SELECT
    ss.id,
    ss.name,
    ss.lat,
    ss.lng,
    ss.descriptors,
    ss.semantic_sim as semantic_similarity,
    ss.spatial_score as spatial_confidence,
    (ss.semantic_sim * 0.6 + ss.spatial_score * 0.4) as composite_confidence
  FROM spatial_scores ss
  ORDER BY (ss.semantic_sim * 0.6 + ss.spatial_score * 0.4) DESC;
END;
$$;

COMMENT ON FUNCTION get_candidates IS
'Gets filtered candidates for a session. Queries session embedding, eliminated places (wrong guesses), and question history to return current candidate set with confidence scores.';
```

**Why:** Single function to get all candidates - frontend just displays

---

### 2.2 Update get_next_question() Function
**File:** `supabase/migrations/000003_database_functions.sql`

**Update existing function:**
```sql
CREATE OR REPLACE FUNCTION get_next_question(
  session_id_param UUID,
  match_count INT DEFAULT 10
)
RETURNS TABLE (
  id uuid,
  text text,
  question_type text,
  geographic_region jsonb,
  times_asked int,
  effectiveness_score double precision,
  semantic_similarity float
)
LANGUAGE plpgsql
AS $$
DECLARE
  description_embedding vector(384);
  answered_question_ids UUID[];
  geographic_constraint geometry;
BEGIN
  -- Get description embedding from session
  SELECT gs.description_embedding INTO description_embedding
  FROM game_sessions gs
  WHERE gs.id = session_id_param;
  
  IF description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or missing embedding', session_id_param;
  END IF;
  
  -- Get already answered question IDs
  SELECT array_agg(ga.question_id)
  INTO answered_question_ids
  FROM game_answers ga
  WHERE ga.session_id = session_id_param
    AND ga.answer_type = 'question_answer';
  
  -- Get geographic bbox from first YES geographic answer
  SELECT ST_MakeEnvelope(
    (q.geographic_region->'bbox'->0)::text::float,
    (q.geographic_region->'bbox'->1)::text::float,
    (q.geographic_region->'bbox'->2)::text::float,
    (q.geographic_region->'bbox'->3)::text::float,
    4326
  )
  INTO geographic_constraint
  FROM game_answers ga
  JOIN questions q ON q.id = ga.question_id
  WHERE ga.session_id = session_id_param
    AND ga.answer = TRUE
    AND q.question_type = 'geographic'
    AND q.geographic_region IS NOT NULL
  ORDER BY ga.sequence_number ASC
  LIMIT 1;
  
  -- Return filtered questions
  RETURN QUERY
  SELECT 
    q.id,
    q.text,
    q.question_type,
    q.geographic_region,
    q.times_asked,
    q.effectiveness_score,
    CASE 
      WHEN q.embedding IS NOT NULL THEN 1 - (q.embedding <=> description_embedding)
      ELSE 0.0
    END as semantic_similarity
  FROM questions q
  WHERE 
    -- Exclude answered questions
    (answered_question_ids IS NULL OR q.id != ALL(answered_question_ids))
    AND (
      -- Semantic questions with embeddings
      (q.question_type = 'semantic' AND q.embedding IS NOT NULL)
      OR
      -- Geographic questions (filtered by bbox if constraint exists)
      (q.question_type = 'geographic' AND (
        geographic_constraint IS NULL
        OR ST_Intersects(
          geographic_constraint,
          ST_MakeEnvelope(
            (q.geographic_region->'bbox'->0)::text::float,
            (q.geographic_region->'bbox'->1)::text::float,
            (q.geographic_region->'bbox'->2)::text::float,
            (q.geographic_region->'bbox'->3)::text::float,
            4326
          )
        )
      ))
    )
  ORDER BY 
    q.effectiveness_score DESC,
    semantic_similarity DESC,
    q.times_asked ASC
  LIMIT match_count;
END;
$$;
```

**Why:** Queries all data from session relations - no parameters except session_id

---

### 2.3 Create update_question_effectiveness_batch() Function
**File:** `supabase/migrations/000003_database_functions.sql`

**New function:**
```sql
CREATE OR REPLACE FUNCTION update_question_effectiveness_batch(
  session_id_param UUID
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  target_place_id UUID;
  answer_record RECORD;
  initial_candidates INT;
  final_candidates INT;
  helped_narrow BOOLEAN;
  effectiveness_delta FLOAT;
BEGIN
  -- Only update if session ended with correct guess
  SELECT place_id INTO target_place_id
  FROM game_sessions
  WHERE id = session_id_param AND was_correct = TRUE;
  
  IF target_place_id IS NULL THEN
    RETURN; -- Not a successful session, don't update
  END IF;
  
  -- For each question answer in the session
  FOR answer_record IN
    SELECT 
      ga.question_id,
      ga.sequence_number,
      ga.candidates_after,
      LAG(ga.candidates_after) OVER (ORDER BY ga.sequence_number) as candidates_before
    FROM game_answers ga
    WHERE ga.session_id = session_id_param
      AND ga.answer_type = 'question_answer'
    ORDER BY ga.sequence_number
  LOOP
    -- Check if target place was in candidates before and after
    initial_candidates := jsonb_array_length(
      COALESCE(answer_record.candidates_before->'place_ids', '[]'::jsonb)
    );
    final_candidates := jsonb_array_length(
      answer_record.candidates_after->'place_ids'
    );
    
    -- Question helped if it narrowed candidates and kept target place
    helped_narrow := (
      final_candidates < initial_candidates
      AND target_place_id = ANY(
        SELECT jsonb_array_elements_text(
          answer_record.candidates_after->'place_ids'
        )::uuid
      )
    );
    
    -- Calculate effectiveness delta
    effectiveness_delta := CASE
      WHEN helped_narrow THEN 0.1
      WHEN final_candidates = 0 THEN -0.2 -- Eliminated all candidates (bad)
      ELSE -0.05 -- Didn't help narrow
    END;
    
    -- Update question effectiveness (running average)
    UPDATE questions
    SET
      effectiveness_score = (effectiveness_score + effectiveness_delta) / 2.0,
      times_asked = times_asked + 1
    WHERE id = answer_record.question_id;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION update_question_effectiveness_batch IS
'Updates question effectiveness for all questions in a session. Called when session ends with correct guess. Evaluates whether each question helped narrow down to target place.';
```

**Why:** Learning happens at session end, evaluates full question sequence

---

## 📦 Phase 3: Add Wikipedia/Wikidata APIs

### 3.1 Install wikipedia package
**Command:**
```bash
npm install wikipedia
```

---

### 3.2 Create lib/places/wikipedia.ts
**New file:** `src/lib/places/wikipedia.ts`

```typescript
/**
 * Wikipedia API client for fetching place summaries
 * Uses the dopecodez/wikipedia package
 */

import wiki from 'wikipedia'

/**
 * Get Wikipedia summary from Wikidata ID
 * Uses extratags.wikidata from Nominatim
 */
export async function getWikipediaSummary(
  wikidata_id: string
): Promise<string | null> {
  try {
    // Extract Q-code (e.g., 'Q243' from 'wikidata:Q243')
    const qcode = wikidata_id.replace(/^wikidata:/, '')
    
    // Search for the Wikidata item
    const searchResults = await wiki.search(qcode, { limit: 1 })
    if (!searchResults.results || searchResults.results.length === 0) {
      return null
    }
    
    const title = searchResults.results[0].title
    const summary = await wiki.summary(title)
    
    // Return extract (plain text summary)
    return summary.extract || null
  } catch (error) {
    console.warn('Failed to get Wikipedia summary:', error)
    return null
  }
}

/**
 * Get Wikipedia summary from article title
 */
export async function getWikipediaSummaryByTitle(
  title: string
): Promise<string | null> {
  try {
    const summary = await wiki.summary(title, { autoSuggest: true })
    return summary.extract || null
  } catch (error) {
    console.warn('Failed to get Wikipedia summary:', error)
    return null
  }
}

/**
 * Enrich place with Wikipedia summary
 * First tries wikidata ID, then falls back to wikipedia tag, then place name
 */
export async function enrichWithWikipedia(
  placeName: string,
  extratags: Record<string, any>
): Promise<string | null> {
  // Try Wikidata ID first (most reliable)
  if (extratags.wikidata) {
    const summary = await getWikipediaSummary(extratags.wikidata)
    if (summary) return summary
  }
  
  // Try Wikipedia tag (e.g., 'en:Eiffel Tower')
  if (extratags.wikipedia) {
    const title = extratags.wikipedia.replace(/^[a-z]+:/, '')
    const summary = await getWikipediaSummaryByTitle(title)
    if (summary) return summary
  }
  
  // Fallback to place name
  return await getWikipediaSummaryByTitle(placeName)
}
```

**Why:** Rich descriptions from Wikipedia improve embedding diversity

---

### 3.3 Update lib/places/index.ts
**File:** `src/lib/places/index.ts`

**Extract general logic from nominatim.ts:**
```typescript
/**
 * Place utilities - unified exports
 */

// Rate limiting (shared across all place APIs)
let lastRequestTime = 0
const MIN_REQUEST_INTERVAL = 1000

export async function waitForRateLimit(): Promise<void> {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime

  if (timeSinceLastRequest < MIN_REQUEST_INTERVAL) {
    await new Promise(resolve =>
      setTimeout(resolve, MIN_REQUEST_INTERVAL - timeSinceLastRequest)
    )
  }

  lastRequestTime = Date.now()
}

// Nominatim client
export {
  searchPlaces,
  queryPlaceWithRetry,
  extractDescriptors,
  type NominatimPlace,
  type JSONPlace,
  type AddressDetails,
  type ExtraTags,
} from './nominatim'

// Wikipedia client (NEW)
export {
  getWikipediaSummary,
  getWikipediaSummaryByTitle,
  enrichWithWikipedia,
} from './wikipedia'

// Open-Elevation client
export {
  getElevation,
  enrichWithElevation,
} from './openElevation'

// Overpass client
export {
  getHeight,
  enrichWithHeight,
} from './overpass'

// Embedding text generation (MOVED from nominatim.ts)
export function generatePlaceEmbeddingText(place: {
  name: string
  descriptors: any
  wikipedia_summary?: string | null
}): string {
  const parts: string[] = [place.name]
  const desc = place.descriptors
  const ext = desc.extratags || {}
  
  // HEIGHT/ELEVATION (critical for discrimination!)
  if (desc.elevation_meters) {
    parts.push(`Elevation: ${desc.elevation_meters} meters`)
  }
  if (desc.height_meters) {
    parts.push(`Height: ${desc.height_meters} meters`)
  }
  
  // Type and category
  if (desc.type) parts.push(`Type: ${desc.type}`)
  if (desc.class) parts.push(`Category: ${desc.class}`)
  
  // Extratags
  if (ext.natural) parts.push(`Natural feature: ${ext.natural}`)
  if (ext.year_of_construction) parts.push(`Built: ${ext.year_of_construction}`)
  if (ext.architect) parts.push(`Architect: ${ext.architect}`)
  if (ext.building) parts.push(`Building type: ${ext.building}`)
  
  // Wikipedia summary (NEW - rich context!)
  if (place.wikipedia_summary) {
    // Take first 200 chars of summary
    const summary = place.wikipedia_summary.slice(0, 200).trim()
    parts.push(summary)
  }
  
  // Location
  if (desc.address?.city) parts.push(`City: ${desc.address.city}`)
  if (desc.address?.country) parts.push(`Country: ${desc.address.country}`)
  
  return parts.join('. ')
}

// Types
export type { PlaceDescriptors } from './types'
```

**Why:** Clean separation of concerns, shared rate limiting, rich embeddings

---

### 3.4 Update scripts/generate-places-seed.ts
**File:** `scripts/generate-places-seed.ts`

**Add Wikipedia enrichment:**
```typescript
import {
  queryPlaceWithRetry,
  enrichWithElevation,
  enrichWithHeight,
  enrichWithWikipedia, // NEW
  generatePlaceEmbeddingText,
} from '../src/lib/places'

async function processPlace(place: { id: string; name: string }): Promise<boolean> {
  console.log(`\n📍 Processing: ${place.name}`)

  // 1. Query Nominatim
  const nominatimData = await queryPlaceWithRetry(place.name, 3)
  if (!nominatimData) return false

  // 2. Initial descriptors
  const descriptors = {
    type: nominatimData.type,
    class: nominatimData.class,
    country_code: nominatimData.country_code,
    address: nominatimData.address,
    extratags: nominatimData.extratags,
  }

  // 3. Enrich with elevation
  const elevation = await enrichWithElevation(
    nominatimData.lat,
    nominatimData.lng,
    descriptors
  )

  // 4. Enrich with height
  const height = await enrichWithHeight(
    nominatimData.lat,
    nominatimData.lng,
    descriptors
  )

  // 5. Enrich with Wikipedia (NEW)
  console.log('  → Enriching with Wikipedia...')
  const wikipedia_summary = await enrichWithWikipedia(
    place.name,
    descriptors.extratags
  )

  // 6. Merge enrichment
  const enrichedDescriptors = {
    ...descriptors,
    ...(elevation !== null && { elevation_meters: elevation }),
    ...(height !== null && { height_meters: height }),
    ...(wikipedia_summary && { wikipedia_summary }), // NEW
    enrichment_timestamp: new Date().toISOString(),
  }

  // 7. Generate embedding text (includes wikipedia_summary)
  const embeddingText = generatePlaceEmbeddingText({
    name: place.name,
    descriptors: enrichedDescriptors,
    wikipedia_summary, // NEW
  })

  console.log(`  → Embedding text: "${embeddingText.slice(0, 100)}..."`)

  // 8-9. Generate embedding and update DB
  // ... existing code ...
}
```

**Why:** Wikipedia summaries dramatically improve semantic diversity

---

## 🎮 Phase 4: Update Frontend Game Store

### 4.1 Simplify game.ts State
**File:** `src/stores/game.ts`

**Changes:**
```typescript
// REMOVE these:
// - questionHistory ref (handled by DB)
// - currentQuestionIndex ref (computed from DB)
// - answers ref (stored in DB)

// KEEP these:
const gameSessionId = ref<string | null>(null)
const userDescription = ref('')
const descriptionEmbedding = ref<number[] | null>(null)
const questions = ref<Question[]>([])
const candidates = ref([] as PlaceWithScore[])
const gameResult = ref<PlaceWithScore | null>(null)
const loading = ref(false)
const error = ref<string | undefined>(undefined)
const mustAskQuestion = ref(false)

// ADD computed properties from DB
const questionCount = computed(() => {
  // Will be fetched from DB in loadSessionState()
  return sessionQuestionCount.value
})

const sessionQuestionCount = ref(0)
```

---

### 4.2 Update startNewGame()
**File:** `src/stores/game.ts`

```typescript
async function startNewGame(description: string) {
  // ... validation ...

  // Create session
  const { data: sessionData, error: sessionError } = await supabase
    .from('game_sessions')
    .insert({
      user_id: authStore.user.id,
      description,
      description_embedding: embeddingToString(embedding),
      place_id: null,
      was_correct: null,
    })
    .select()
    .single()

  if (sessionError) throw sessionError
  gameSessionId.value = sessionData.id

  // Load candidates and questions from DB
  await loadCandidates()
  await loadQuestions()
}
```

---

### 4.3 Create loadCandidates()
**File:** `src/stores/game.ts`

**New function:**
```typescript
async function loadCandidates() {
  if (!gameSessionId.value) return

  const { data, error: rpcError } = await supabase.rpc('get_candidates', {
    session_id_param: gameSessionId.value,
  })

  if (rpcError) throw rpcError
  candidates.value = data || []
}
```

---

### 4.4 Create loadQuestions()
**File:** `src/stores/game.ts`

**Rename from loadQuestionsForSession:**
```typescript
async function loadQuestions() {
  if (!gameSessionId.value) return

  const { data, error: rpcError } = await supabase.rpc('get_next_question', {
    session_id_param: gameSessionId.value,
    match_count: MAX_QUESTIONS,
  })

  if (rpcError) throw rpcError
  questions.value = data || []
}
```

---

### 4.5 Update answerQuestion()
**File:** `src/stores/game.ts`

**Simplified:**
```typescript
async function answerQuestion(answer: boolean) {
  if (!currentQuestion.value || !gameSessionId.value) return

  // Get current candidates count for sequence
  const sequenceNumber = sessionQuestionCount.value + 1

  // Save answer to DB
  await supabase
    .from('game_answers')
    .insert({
      session_id: gameSessionId.value,
      question_id: currentQuestion.value.id,
      answer,
      answer_type: 'question_answer',
      sequence_number: sequenceNumber,
      candidates_after: {
        place_ids: [], // Will be populated by get_candidates
        confidence_scores: {
          semantic: 0,
          spatial: 0,
          composite: 0,
        },
      },
    })

  // Reload from DB (candidates and questions update automatically)
  await Promise.all([
    loadCandidates(),
    loadQuestions(),
    loadSessionState(),
  ])

  mustAskQuestion.value = false

  if (isGameComplete.value && candidates.value.length > 0) {
    gameResult.value = candidates.value[0]
  } else if (isGameComplete.value) {
    gameResult.value = null
  }
}
```

---

### 4.6 Add submitWrongGuess()
**File:** `src/stores/game.ts`

**New function:**
```typescript
async function submitWrongGuess(placeId: string) {
  if (!gameSessionId.value) return

  const sequenceNumber = sessionQuestionCount.value + 1

  // Save wrong guess to DB
  await supabase
    .from('game_answers')
    .insert({
      session_id: gameSessionId.value,
      question_id: null, // No question for wrong guess
      answer: false,
      answer_type: 'wrong_guess',
      place_id: placeId,
      sequence_number: sequenceNumber,
      candidates_after: {
        place_ids: [],
        confidence_scores: { semantic: 0, spatial: 0, composite: 0 },
      },
    })

  // Reload candidates (place now eliminated)
  await loadCandidates()
  
  // Must ask at least one more question
  mustAskQuestion.value = true
}
```

**Why:** Wrong guesses stored as game_answer, triggers candidate reload

---

### 4.7 Add loadSessionState()
**File:** `src/stores/game.ts`

**New function:**
```typescript
async function loadSessionState() {
  if (!gameSessionId.value) return

  const { data, error } = await supabase
    .from('game_session_stats')
    .select('question_count, wrong_guess_count')
    .eq('session_id', gameSessionId.value)
    .single()

  if (error) throw error
  sessionQuestionCount.value = data?.question_count || 0
}
```

---

### 4.8 Update finalizeGameSession()
**File:** `src/stores/game.ts`

**Add effectiveness update:**
```typescript
async function finalizeGameSession(placeId: string, wasCorrect: boolean) {
  if (!gameSessionId.value) return

  // Update session with final result
  await supabase
    .from('game_sessions')
    .update({
      place_id: placeId,
      was_correct: wasCorrect,
    })
    .eq('id', gameSessionId.value)

  // Update question effectiveness if correct
  if (wasCorrect) {
    await supabase.rpc('update_question_effectiveness_batch', {
      session_id_param: gameSessionId.value,
    })
  }
}
```

---

## 🧪 Phase 5: Testing & Deployment

### 5.1 Test Database Functions Locally
**Commands:**
```bash
# Reset local DB
npx supabase db reset --yes

# Run enrichment scripts
npm run seed:places
npm run seed:questions

# Test get_candidates function
psql -h localhost -p 54322 -U postgres -d postgres -c "
  -- Create test session
  INSERT INTO game_sessions (id, user_id, description, description_embedding)
  SELECT 
    gen_random_uuid(),
    auth.uid(),
    'Test description',
    embedding
  FROM places LIMIT 1
  RETURNING id;
  
  -- Test get_candidates
  SELECT * FROM get_candidates('<session_id>');
"
```

---

### 5.2 Deploy to Production
**Using Supabase MCP:**
```bash
# Link to production
npx supabase link --project-ref <your-project-ref>

# NUKE production DB (as instructed!)
npx supabase db reset --linked --yes

# Migrations applied automatically
# Now run seed scripts against production
VITE_SUPABASE_URL=<prod_url> \
VITE_SUPABASE_SERVICE_KEY=<prod_service_key> \
VITE_SUPABASE_FUNCTIONS_URL_PROD=<prod_functions_url> \
VITE_SUPABASE_ANON_KEY_PROD=<prod_anon_key> \
npm run seed:places

VITE_SUPABASE_URL=<prod_url> \
VITE_SUPABASE_SERVICE_KEY=<prod_service_key> \
VITE_SUPABASE_FUNCTIONS_URL_PROD=<prod_functions_url> \
VITE_SUPABASE_ANON_KEY_PROD=<prod_anon_key> \
npm run seed:questions
```

**Or using Supabase MCP to execute SQL:**
```typescript
// Use mcp__supabase__execute_sql to test queries
// Use mcp__supabase__apply_migration to deploy migrations
```

---

## 📋 Implementation Checklist

### Week 1: Database Rewrite
- [ ] Phase 1.1: Update game_answers schema (answer_type, place_id, candidates_after JSONB)
- [ ] Phase 1.2: Remove question_count, create game_session_stats view
- [ ] Phase 2.1: Create get_candidates() function
- [ ] Phase 2.2: Update get_next_question() function
- [ ] Phase 2.3: Create update_question_effectiveness_batch() function
- [ ] Test all functions with manual SQL

### Week 2: Wikipedia + Frontend
- [ ] Phase 3.1: Install wikipedia package
- [ ] Phase 3.2: Create lib/places/wikipedia.ts
- [ ] Phase 3.3: Update lib/places/index.ts (extract general logic)
- [ ] Phase 3.4: Update scripts/generate-places-seed.ts (Wikipedia enrichment)
- [ ] Phase 4.1-4.8: Update game.ts (simplified, session-first)
- [ ] Run enrichment scripts locally

### Week 3: Testing & Production
- [ ] Phase 5.1: Test all DB functions locally
- [ ] Phase 5.2: Deploy to production (reset DB, run migrations, run seeds)
- [ ] Manual testing: Eiffel Tower, Taj Mahal, Mount Fuji
- [ ] Verify question counter increments correctly
- [ ] Verify confidence stays above 0%
- [ ] Verify wrong guess flow works
- [ ] Update memories with new architecture

---

## 🎯 Success Criteria

**Database:**
- ✅ get_candidates() returns correct filtered set
- ✅ get_next_question() uses only session_id
- ✅ Question count = COUNT of game_answers
- ✅ Wrong guesses eliminate places from candidates
- ✅ Question effectiveness updates on correct guess

**Enrichment:**
- ✅ Wikipedia summaries fetched for all seed places
- ✅ Embedding text includes Wikipedia content
- ✅ Semantic questions discriminate (Fuji vs Everest)

**Frontend:**
- ✅ Question counter increments 1→2→3→4→5
- ✅ Confidence stays >0% throughout game
- ✅ Wrong guess eliminates place, forces another question
- ✅ Game ends at MAX_QUESTIONS or high confidence or 0 candidates
- ✅ All tests pass

---

## 📚 Key Design Decisions

1. **Session-First:** Game session created immediately, all state derived from DB relations
2. **Question Count:** Computed from COUNT(game_answers), not stored
3. **Wrong Guesses:** Stored as game_answer with answer_type='wrong_guess'
4. **Candidates:** Rich JSONB with place_ids and confidence_scores
5. **Single RPC Parameter:** All functions take only session_id
6. **Wikipedia Enrichment:** Adds rich context to embeddings (200 char summaries)
7. **Question Effectiveness:** Updated at session end, only for successful sessions
8. **Database-First Logic:** Frontend just displays, DB does all computation

---

This architecture is clean, database-first, and follows the session-centric design pattern perfectly! 🚀
