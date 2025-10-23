# Game: Question System

## Question Selection Algorithm

### Overview
The system intelligently selects questions that best discriminate between current candidates using semantic matching and effectiveness scores.

**Database Function:** `get_next_question(session_id, match_count)`  
**Location:** `supabase/migrations/000003_database_functions.sql`

### Selection Process

**Phase 1: Filter Already Asked Questions**
```sql
WHERE q.id NOT IN (
  SELECT question_id 
  FROM game_answers 
  WHERE session_id = p_session_id
    AND answer_type = 'question_answer'
)
```

**Phase 2: Calculate Base Score**
```sql
CASE 
  WHEN q.question_type = 'geographic' THEN 0.6
  WHEN q.effectiveness_score > 0 THEN q.effectiveness_score
  ELSE 0.4
END as base_score
```

**Why geographic questions get 0.6:**
- They always narrow candidates through PostGIS bbox filtering
- More reliable than semantic questions initially
- Ensures geographic questions appear in top 10

**Phase 3: Semantic Matching with Candidates**
```sql
AVG(1 - (c.embedding <=> q.embedding)) as semantic_match
```

**How it works:**
- Cross join current candidates with questions
- Calculate cosine similarity between each candidate and question
- Average similarity across all candidates
- Questions relevant to current candidates score higher

**Example:**
- Candidates: Eiffel Tower, Arc de Triomphe, Notre Dame (all in Paris)
- Question: "Is it a religious building?"
- Semantic match: HIGH (Notre Dame's embedding matches)
- Result: Question appears in top selections

**Phase 4: Combine Scores**
```sql
ORDER BY (base_score + semantic_match) DESC
LIMIT 10
```

**Final score = base_score + semantic_match**
- base_score: 0.4-0.6 (effectiveness or type-based)
- semantic_match: 0.0-1.0 (similarity to candidates)
- Range: 0.4-1.6

## Question Types

### Geographic Questions
**Characteristics:**
- `question_type = 'geographic'`
- Have `bbox` (PostGIS geometry - bounding box)
- Always visible (0.6 baseline score)

**Examples:**
```sql
{
  "text": "Is it in Europe?",
  "question_type": "geographic",
  "bbox": ST_MakeEnvelope(-10, 36, 40, 71, 4326)
}
```

**Filtering Logic:**
- YES answer: Candidate must be WITHIN bbox
- NO answer: Candidate must be OUTSIDE bbox
- Uses PostGIS `ST_Within()` for precision

**Benefits:**
- Guaranteed to narrow candidates
- No false positives (spatial math is absolute)
- Scales to any geographic region

### Semantic Questions
**Characteristics:**
- `question_type = 'semantic'`
- No bbox, relies on embeddings
- Effectiveness score determines visibility

**Examples:**
```sql
{
  "text": "Is it very tall?",
  "question_type": "semantic",
  "embedding": vector(384)
}
```

**Filtering Logic:**
- YES answer: Boost confidence by similarity
- NO answer: Penalize confidence by similarity
- No hard elimination (too risky without field checks)

**Semantic Boost Calculation:**
```sql
semantic_boost = AVG(
  CASE 
    WHEN answer = true THEN (1 - place.embedding <=> question.embedding)
    ELSE -(1 - place.embedding <=> question.embedding)
  END
) * 0.3
```

**Example:**
- Question: "Is it very tall?"
- Place: Burj Khalifa (embedding similarity: 0.85)
- Answer: YES
- Boost: +0.85 * 0.3 = +0.255 confidence

**Benefits:**
- Works with any natural language question
- No hardcoded field checks needed
- Learns from embedding quality

**Limitations:**
- Depends on place embedding quality
- Can't eliminate candidates (only adjust confidence)
- Requires rich place descriptions for accuracy

## Question Effectiveness System

### Tracking Effectiveness

**Database Column:** `questions.effectiveness_score` (float, 0.0-1.0)

**Updated After Each Game:**
```sql
CREATE FUNCTION update_question_effectiveness_batch(
  p_session_id uuid
) RETURNS void
```

**Only Runs If:**
- Game was successful (correct guess)
- Session has question answers

### Effectiveness Calculation

**Criteria:**
1. Did the question narrow candidates?
2. Did it keep the target place?

**Formula:**
```typescript
let effectiveness_delta = 0

// Narrowed candidates = good
if (final_count < initial_count) {
  effectiveness_delta += 0.1
} else if (final_count === initial_count) {
  // No change = neutral
  effectiveness_delta -= 0.05
} else {
  // Increased candidates = bad (shouldn't happen)
  effectiveness_delta -= 0.1
}

// Apply learning rate
effectiveness_score = CLAMP(
  effectiveness_score + 0.2 * effectiveness_delta,
  0.0,
  1.0
)
```

**Learning Rate:** 0.2 (adjustable)  
**Bounds:** [0.0, 1.0]

### Example Scenario

**Game Session:**
- Target: Eiffel Tower
- Initial candidates: 15 places
- Question 1: "Is it in Europe?" (geographic)
  - Answer: YES
  - Candidates before: 15
  - Candidates after: 8
  - Narrowed: ✅ (+0.1 * 0.2 = +0.02)
  
- Question 2: "Is it very tall?" (semantic)
  - Answer: YES
  - Candidates before: 8
  - Candidates after: 3
  - Narrowed: ✅ (+0.1 * 0.2 = +0.02)

**Result:**
- Both questions gain +0.02 effectiveness
- Will be prioritized in future games

### Cold Start Problem

**New Questions:**
- Start with `effectiveness_score = 0.4`
- Geographic questions get 0.6 baseline (always useful)
- Learn effectiveness over time

**Why 0.4 default:**
- Below geographic baseline (0.6)
- Above minimum threshold
- Ensures some visibility initially

## Question Management

### Adding New Questions

**Process:**
1. Insert into `questions` table
2. Generate embedding (Edge Function)
3. Set question_type and optional bbox
4. No code changes needed!

**Geographic Question:**
```sql
INSERT INTO questions (text, question_type, bbox) VALUES
  (
    'Is it in Southeast Asia?',
    'geographic',
    ST_MakeEnvelope(95, -10, 140, 20, 4326)
  );
```

**Semantic Question:**
```sql
INSERT INTO questions (text, question_type) VALUES
  ('Is it a modern structure?', 'semantic');
  
-- Then generate embedding
SELECT generate_embedding('Is it a modern structure?');
```

**Benefits:**
- No deployment needed
- Instant availability
- Effectiveness learned automatically

### Question Quality Guidelines

**Good Questions:**
- Clear and unambiguous
- Discriminate between place types
- Not too broad ("Is it on Earth?") or too narrow ("Is it exactly 324m tall?")

**Geographic Questions:**
- Define meaningful regions
- Not too large (continents OK, hemispheres too big)
- Not too small (cities OK, streets too small)

**Semantic Questions:**
- Natural language phrasing
- Characteristics that affect embeddings
- Avoid specific facts better suited for exact matching

## Performance Optimizations

### Vector Similarity Indexing
```sql
CREATE INDEX idx_questions_embedding ON questions 
USING hnsw (embedding vector_cosine_ops);
```

**Benefits:**
- Fast similarity search (O(log n))
- Scales to thousands of questions
- Approximate nearest neighbor

### Caching Strategy

**Frontend:**
- Cache current session's question history
- No need to refetch already asked questions
- Store in game store

**Database:**
- Questions table is read-heavy (rarely updated)
- PostgreSQL query cache handles this well

### Question Selection Performance

**Complexity:**
- O(q * c) where q = questions, c = candidates
- Typical: 50 questions × 20 candidates = 1,000 operations
- Fast due to vector indexes

## Testing Strategy

### Unit Tests (Frontend)
**Location:** `src/__tests__/stores/game.spec.ts`

**Coverage:**
- Question history tracking
- Already asked question filtering
- Question display logic

### Database Tests (pgTAP)
**Location:** `supabase/tests/test_question_effectiveness.sql`

**Coverage:**
- Effectiveness calculation
- Batch update function
- Score bounds (0.0-1.0)
- Learning rate application

### E2E Tests (Playwright)
**Location:** `e2e/complete-game-flow.spec.ts`

**Coverage:**
- Question selection flow
- Answer processing
- Candidate narrowing

## Future Enhancements

### Phase 1: Rich Question Embeddings
**Current:**
```typescript
embedding = generate("Is it very tall?")
```

**Future:**
```typescript
// Add context to question embeddings
embedding = generate(
  "Is it very tall? Tall structures, towers, skyscrapers, " +
  "buildings with significant height above 200 meters."
)
```

**Benefits:**
- Better semantic matching
- Clearer discrimination
- Handles synonyms better

### Phase 2: Multi-Language Questions
- Store questions in multiple languages
- Generate embeddings per language
- Select based on user locale

### Phase 3: Personalized Question Selection
- Track per-user question effectiveness
- Adapt to individual description styles
- Learn user preferences

### Phase 4: Question Categories
- Group related questions
- Ensure coverage across categories
- Avoid asking too many similar questions

## Troubleshooting

### Issue: Same Questions Repeated
**Cause:** Question history not tracked correctly  
**Fix:** Check `game_answers` inserts include `question_id`

### Issue: No Questions Available
**Cause:** All questions already asked or filtered out  
**Fix:** Increase MAX_QUESTIONS or add more questions

### Issue: Irrelevant Questions
**Cause:** Poor semantic matching (low quality embeddings)  
**Fix:** Enrich place descriptions for better embeddings

### Issue: Geographic Question Not Narrowing
**Cause:** Bbox doesn't cover any candidates  
**Fix:** Verify bbox geometry with `ST_Contains()` in SQL

## Key Takeaways

1. **Pure Algorithmic:** No hardcoded question logic
2. **Self-Learning:** Effectiveness improves over time
3. **Scalable:** Add questions via INSERT only
4. **Two Types:** Geographic (spatial) + Semantic (vector)
5. **Semantic Matching:** Questions match candidate context
6. **Effectiveness Tracking:** Learn which questions narrow best
7. **Cold Start:** Geographic questions get 0.6 baseline boost