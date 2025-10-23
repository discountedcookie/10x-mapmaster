# Game: Vector System

## Vector Architecture

### Embedding Model
**Model:** Supabase AI gte-small  
**Dimensions:** 384  
**Type:** Sentence embedding model  
**Quality:** Good balance of accuracy and performance

**Why gte-small:**
- Smaller than sentence-transformers (768d) but comparable accuracy
- Faster cosine similarity computations
- Built into Supabase (no external service)
- Cost-effective for MVP scale

### Vector Storage
```sql
-- PostgreSQL pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Vector columns
ALTER TABLE places ADD COLUMN embedding vector(384);
ALTER TABLE questions ADD COLUMN embedding vector(384);
ALTER TABLE game_sessions ADD COLUMN description_embedding vector(384);

-- HNSW indexes for fast similarity search
CREATE INDEX idx_places_embedding ON places 
USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_questions_embedding ON questions 
USING hnsw (embedding vector_cosine_ops);
```

### Similarity Metric
**Cosine Distance:** `<=>` operator in PostgreSQL

```sql
-- Find top 20 most similar places
SELECT 
  p.*,
  p.embedding <=> $1 AS distance,
  1 - (p.embedding <=> $1) AS similarity
FROM places p
ORDER BY p.embedding <=> $1
LIMIT 20
```

**Why cosine distance:**
- Measures angle between vectors (direction, not magnitude)
- Range: 0 (identical) to 2 (opposite)
- Similarity: `1 - distance` gives 0-1 score
- Normalized (vector magnitude doesn't matter)

## Embedding Generation

### Edge Function
**Location:** `supabase/functions/generate-embedding/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { text } = await req.json()
  
  // Call Supabase AI
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  const { data, error } = await supabase.functions.invoke('embeddings', {
    body: { input: text, model: 'gte-small' }
  })
  
  if (error) throw error
  
  return new Response(
    JSON.stringify({ embedding: data.embedding }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
```

### Frontend Usage
**Composable:** `src/composables/useEmbeddings.ts`

```typescript
export function useEmbeddings() {
  const isGenerating = ref(false)
  
  async function generateEmbedding(text: string): Promise<number[]> {
    isGenerating.value = true
    
    try {
      const { data, error } = await supabase.functions.invoke(
        'generate-embedding',
        { body: { text } }
      )
      
      if (error) throw error
      return data.embedding
    } finally {
      isGenerating.value = false
    }
  }
  
  return { generateEmbedding, isGenerating }
}
```

### Embedding Text Format

**Current (Basic):**
```typescript
const text = `${place.name}. Type: ${place.type}. Category: ${place.class}. Country: ${place.country}`
// Example: "Eiffel Tower. Type: tower. Category: tourism. Country: France"
```

**Future (Rich):**
```typescript
const text = [
  place.name,
  place.wikipedia_extract, // First paragraph from Wikipedia
  `Type: ${place.type}`,
  `Height: ${place.height_meters}m`,
  `Built: ${place.construction_year}`,
  `Location: ${place.city}, ${place.country}`,
  place.descriptors.extratags?.natural && `Natural feature: ${place.descriptors.extratags.natural}`
].filter(Boolean).join('. ')

// Example: "Eiffel Tower. Wrought-iron lattice tower on the Champ de Mars in Paris, France. 
//           Type: tower. Height: 330m. Built: 1889. Location: Paris, France"
```

**Impact:** Richer text = better semantic discrimination

## Vector Similarity in Game Flow

### Phase 1: Initial Candidate Retrieval
```sql
-- get_candidates() function
WITH vector_matches AS (
  SELECT 
    p.*,
    1 - (p.embedding <=> session.description_embedding) AS semantic_score
  FROM places p
  CROSS JOIN game_sessions session
  WHERE session.id = p_session_id
  ORDER BY p.embedding <=> session.description_embedding
  LIMIT 20 -- Top 20 candidates only
)
```

**Why limit to 20:**
- Balance between recall and performance
- Reduces PostGIS computation overhead
- Top 20 usually includes target place

### Phase 3: Semantic Adjustment
```sql
-- Adjust confidence based on answered questions
semantic_boost = AVG(
  CASE 
    WHEN ga.answer = true THEN (1 - (p.embedding <=> q.embedding))
    ELSE -(1 - (p.embedding <=> q.embedding))
  END
) * 0.3

final_score = semantic_score + semantic_boost
```

**How it works:**
- YES answers: Boost confidence by similarity to question
- NO answers: Penalize confidence by similarity to question
- Weight: 0.3 (adjustable)

**Example:**
- Question: "Is it very tall?"
- Place: Eiffel Tower (embedding similarity: 0.8)
- Answer: YES
- Boost: +0.8 * 0.3 = +0.24

### Question Selection
```sql
-- get_next_question() function
SELECT 
  q.*,
  AVG(1 - (c.embedding <=> q.embedding)) as semantic_match
FROM questions q
CROSS JOIN current_candidates c
WHERE q.id NOT IN (already_asked_questions)
GROUP BY q.id
ORDER BY (base_score + semantic_match) DESC
LIMIT 10
```

**Why semantic match:**
- Questions relevant to current candidates score higher
- "Is it in Europe?" scores high if candidates are European
- Avoids irrelevant questions

## Learning System

### Place Embedding Updates
**Function:** `update_place_embedding(place_id, new_embedding, learning_rate)`

```sql
CREATE FUNCTION update_place_embedding(
  p_place_id uuid,
  p_new_embedding vector(384),
  p_learning_rate float DEFAULT 0.1
) RETURNS void AS $$
  UPDATE places
  SET 
    embedding = (
      -- Weighted average: old * (1 - rate) + new * rate
      (
        embedding::float[] * (1.0 - p_learning_rate) +
        p_new_embedding::float[] * p_learning_rate
      )::vector(384)
    ),
    game_count = game_count + 1,
    updated_at = now()
  WHERE id = p_place_id;
$$ LANGUAGE sql;
```

**How it works:**
1. User describes "Eiffel Tower" as "Tall iron tower in Paris"
2. System generates embedding for this description
3. If correct guess, update place embedding:
   - Old embedding: 90% weight
   - New embedding: 10% weight
4. Result: Place embedding learns from user descriptions

**Benefits:**
- Improves matching over time
- Learns common ways people describe places
- Organic quality improvement

### Question Effectiveness Updates
**Function:** `update_question_effectiveness_batch(session_id)`

```sql
CREATE FUNCTION update_question_effectiveness_batch(
  p_session_id uuid
) RETURNS void AS $$
DECLARE
  answer_record record;
  effectiveness_delta float;
  initial_candidate_count int;
  final_candidate_count int;
BEGIN
  -- Only process if game was correct
  IF NOT (SELECT was_correct FROM game_sessions WHERE id = p_session_id) THEN
    RETURN;
  END IF;
  
  FOR answer_record IN 
    SELECT * FROM game_answers 
    WHERE session_id = p_session_id 
      AND answer_type = 'question_answer'
    ORDER BY sequence_number
  LOOP
    -- Get candidate counts
    initial_candidate_count := COALESCE(
      jsonb_array_length(answer_record.candidates_before->'place_ids'),
      20 -- First question assumes 20 initial candidates
    );
    final_candidate_count := answer_record.candidates_after;
    
    -- Calculate effectiveness
    IF final_candidate_count < initial_candidate_count THEN
      -- Good: narrowed down candidates
      effectiveness_delta := 0.1;
    ELSIF final_candidate_count = initial_candidate_count THEN
      -- Neutral: no change
      effectiveness_delta := -0.05;
    ELSE
      -- Bad: should not happen
      effectiveness_delta := -0.1;
    END IF;
    
    -- Update question
    UPDATE questions
    SET 
      effectiveness_score = LEAST(1.0, GREATEST(0.0,
        effectiveness_score + 0.2 * effectiveness_delta
      )),
      times_asked = times_asked + 1
    WHERE id = answer_record.question_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

**Learning criteria:**
- **Good question:** Narrowed candidates, kept target
- **Bad question:** Eliminated all candidates including target
- **Neutral question:** Didn't narrow, but kept target

**Bounds:** Effectiveness stays in [0.0, 1.0]

## Place Enrichment

### Current Approach
```typescript
// Minimal text from Nominatim
const text = `${place.name}. Type: ${place.type}. Category: ${place.class}`
```

**Problem:** All similar places (e.g., mountains) have nearly identical embeddings

### Future Approach: Wikipedia Integration

**Step 1:** Extract Wikipedia link from Nominatim
```typescript
const wikipediaUrl = place.extratags?.wikipedia // "en:Eiffel_Tower"
```

**Step 2:** Fetch Wikipedia extract
```typescript
async function getWikipediaExtract(title: string): Promise<string | null> {
  const response = await fetch(
    `https://en.wikipedia.org/w/api.php?` +
    `action=query&format=json&prop=extracts&exintro=true&` +
    `explaintext=true&titles=${encodeURIComponent(title)}&origin=*`
  )
  
  const data = await response.json()
  const pages = data.query.pages
  const page = Object.values(pages)[0]
  
  return page.extract || null
}
```

**Step 3:** Combine for rich embedding
```typescript
const richText = [
  place.name,
  wikipediaExtract, // "Wrought-iron lattice tower on Champ de Mars..."
  `Type: ${place.type}`,
  place.height_meters && `Height: ${place.height_meters}m`,
  `Location: ${place.city}, ${place.country}`
].filter(Boolean).join('. ')
```

**Result:** Better discrimination between similar places

### Future Approach: Structured Data

**Add to seed data:**
```sql
INSERT INTO places (name, lat, lng, descriptors) VALUES
  ('Mount Fuji', 35.3606, 138.7274, '{
    "type": "peak",
    "class": "natural",
    "country_code": "jp",
    "height_meters": 3776,
    "natural_type": "volcano",
    "is_active_volcano": true,
    "unesco_site": true
  }'::jsonb)
```

**Generate embedding from structured + text:**
```typescript
const text = [
  place.name,
  place.descriptors.natural_type && `Natural feature: ${place.descriptors.natural_type}`,
  place.descriptors.height_meters && `Height: ${place.descriptors.height_meters} meters`,
  place.descriptors.is_active_volcano && "Active volcano",
  place.descriptors.unesco_site && "UNESCO World Heritage Site",
  `Country: ${place.country}`
].filter(Boolean).join('. ')
```

## Vector Quality Analysis

### Measuring Quality

**Cosine similarity distribution:**
```sql
-- Check similarity between random place pairs
SELECT 
  AVG(p1.embedding <=> p2.embedding) as avg_distance,
  MIN(p1.embedding <=> p2.embedding) as min_distance,
  MAX(p1.embedding <=> p2.embedding) as max_distance
FROM places p1, places p2
WHERE p1.id < p2.id
LIMIT 1000;
```

**Good distribution:**
- Min: 0.0-0.2 (very similar places)
- Avg: 0.5-0.7 (moderate similarity)
- Max: 0.8-1.0 (very different places)

**Bad distribution:**
- All in 0.6-0.8 range → embeddings too similar (need richer text)

### Known Issues

**Semantic Filtering Bug (Resolved):**
- **Problem:** All semantic questions had similarity 0.734-0.848 to all places
- **Cause:** Minimal embedding text ("peak, natural, Japan")
- **Solution:** Temporarily disabled semantic questions, plan to add rich embeddings

**Solution Status:**
- Migration 000010: Disabled semantic questions
- Future: Add Wikipedia + structured data enrichment

## Performance Considerations

**Indexing:**
- HNSW index: Fast approximate nearest neighbor search
- Build time: O(n log n)
- Query time: O(log n)

**Memory:**
- 384 floats * 4 bytes = 1,536 bytes per embedding
- 1,000 places = 1.5 MB
- Acceptable for MVP scale

**Computation:**
- Cosine distance: O(d) where d = dimensions
- 384 dimensions = fast computation
- PostgreSQL optimized for vector ops

**Optimization tips:**
- Cache embeddings (never regenerate)
- Limit similarity search to top K
- Use HNSW index (not IVFFlat)
- Batch embedding generation for seed data

## Testing Vector Operations

**pgTAP tests:**
```sql
-- Test vector similarity
SELECT ok(
  (SELECT embedding <=> '[0.1, 0.1, ...]'::vector(384) FROM places WHERE name = 'Test Place') < 0.3,
  'Vector similarity should be high for matching description'
);

-- Test distinct embeddings
SELECT ok(
  (SELECT MIN(p1.embedding <=> p2.embedding) FROM places p1, places p2 WHERE p1.id <> p2.id) > 0.1,
  'Embeddings should be sufficiently distinct'
);
```

**Unit tests:**
```typescript
describe('generateEmbedding', () => {
  it('should return 384-dimensional vector', async () => {
    const embedding = await generateEmbedding('Eiffel Tower')
    expect(embedding).toHaveLength(384)
    expect(embedding.every(n => typeof n === 'number')).toBe(true)
  })
})
```