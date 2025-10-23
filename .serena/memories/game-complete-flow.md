# Game: Complete Flow

## End-to-End Game Flow

### 1. Game Start
**User Action:** Enter place description  
**Frontend:** Validate input (10-500 characters)  
**Edge Function:** Generate embedding (384 dimensions)  
**Database:** Create game_session record

```typescript
// Frontend: src/stores/game.ts
async function startGame(description: string) {
  // Generate embedding
  const embedding = await generateEmbedding(description)
  
  // Create session
  const { data: session, error } = await supabase
    .from('game_sessions')
    .insert({
      user_id: currentUser.value!.id,
      description,
      description_embedding: embedding
    })
    .select()
    .single()
  
  if (error) throw error
  currentSession.value = session
}
```

### 2. Initial Candidate Retrieval
**Database Function:** `get_candidates(session_id)`  
**Process:** Vector similarity search + spatial clustering

```sql
-- Phase 1: Vector similarity (top 20)
WITH vector_matches AS (
  SELECT 
    p.*,
    1 - (p.embedding <=> description_embedding) AS semantic_score
  FROM places p
  WHERE NOT EXISTS (
    SELECT 1 FROM game_answers
    WHERE session_id = p_session_id
      AND answer_type = 'wrong_guess'
      AND place_id = p.id
  )
  ORDER BY p.embedding <=> description_embedding
  LIMIT 20
)

-- Phase 2: Geographic filtering (PostGIS)
-- Phase 3: Semantic adjustment (question similarity)
-- Phase 4: Spatial confidence (cluster analysis)
```

**Frontend:** Display candidates on map with confidence scores

### 3. Question Selection
**Condition:** If top confidence < 70% OR user rejected guess  
**Database Function:** `get_next_question(session_id, match_count)`  
**Process:** Semantic matching between candidates and questions

```sql
-- Find questions that best discriminate current candidates
SELECT 
  q.*,
  -- Baseline score from question metadata
  CASE 
    WHEN q.question_type = 'geographic' THEN 0.6
    WHEN q.effectiveness_score > 0 THEN q.effectiveness_score
    ELSE 0.4
  END as base_score,
  
  -- Semantic match with candidates
  AVG(1 - (c.embedding <=> q.embedding)) as semantic_match
FROM questions q
CROSS JOIN current_candidates c
WHERE q.id NOT IN (already_asked_questions)
GROUP BY q.id
ORDER BY (base_score + semantic_match) DESC
LIMIT 10
```

**Frontend:** Display question with YES/NO buttons

### 4. Answer Processing
**User Action:** Click YES or NO  
**Frontend:** Insert game_answer record  
**Database:** Update candidate list based on answer

```typescript
// Frontend: src/stores/game.ts
async function answerQuestion(questionId: string, answer: boolean) {
  // Get current candidates before answer
  const candidatesBefore = { place_ids: topCandidates.value.map(c => c.id) }
  
  // Insert answer
  await supabase
    .from('game_answers')
    .insert({
      session_id: currentSession.value!.id,
      question_id: questionId,
      answer,
      answer_type: 'question_answer',
      candidates_before: candidatesBefore,
      sequence_number: questionHistory.value.length + 1
    })
  
  // Fetch updated candidates
  await fetchCandidates()
}
```

**Filtering Logic (Database):**

**Geographic Questions:**
- YES answer: Candidate must be WITHIN bbox
- NO answer: Candidate must be OUTSIDE bbox

```sql
WHERE NOT EXISTS (
  SELECT 1 FROM answered_geographic
  WHERE (answer = true AND NOT ST_Within(place.geom, bbox))
     OR (answer = false AND ST_Within(place.geom, bbox))
)
```

**Semantic Questions:**
- YES answer: Boost confidence by similarity
- NO answer: Penalize confidence by similarity

```sql
semantic_boost = AVG(
  CASE 
    WHEN answer = true THEN (1 - place.embedding <=> question.embedding)
    ELSE -(1 - place.embedding <=> question.embedding)
  END
) * 0.3
```

### 5. Repeat or Guess Decision
**Frontend Decision Logic:**

```typescript
const shouldGuess = computed(() => {
  // No candidates left
  if (topCandidates.value.length === 0) return false
  
  // Max questions reached
  if (questionHistory.value.length >= MAX_QUESTIONS) return true
  
  // High confidence and not forced to ask question
  if (topConfidence.value >= MIN_CONFIDENCE && !mustAskQuestion.value) {
    return true
  }
  
  return false
})
```

**Repeat:** Go back to step 3 (Question Selection)  
**Guess:** Proceed to step 6

### 6. Make Guess
**Frontend:** Display top candidate with confidence  
**User Options:**
- Confirm correct
- Reject (wrong guess)

### 7A. Correct Guess Flow
**User Action:** Confirm guess is correct  
**Frontend:** Update game_session

```typescript
async function finalizeTurn(wasCorrect: boolean) {
  await supabase
    .from('game_sessions')
    .update({
      place_id: guess.value!.id,
      was_correct: wasCorrect
    })
    .eq('id', currentSession.value!.id)
  
  if (wasCorrect) {
    // Trigger learning
    await supabase.rpc('update_question_effectiveness_batch', {
      p_session_id: currentSession.value!.id
    })
    
    // Update place embedding (weighted average)
    await supabase.rpc('update_place_embedding', {
      p_place_id: guess.value!.id,
      p_new_embedding: currentSession.value!.description_embedding,
      p_learning_rate: 0.1
    })
  }
}
```

**Learning Process:**
1. Update question effectiveness scores
2. Update place embedding with user description
3. Increment place game_count

### 7B. Wrong Guess Flow
**User Action:** Reject guess  
**Frontend:** Insert game_answer with wrong guess

```typescript
async function rejectGuess() {
  // Record wrong guess
  await supabase
    .from('game_answers')
    .insert({
      session_id: currentSession.value!.id,
      answer_type: 'wrong_guess',
      place_id: guess.value!.id,
      sequence_number: questionHistory.value.length + 1
    })
  
  // Set flag to require at least one question before next guess
  mustAskQuestion.value = true
  
  // Fetch updated candidates (excluded wrong guess)
  await fetchCandidates()
}
```

**Process:**
- Wrong guess excluded from future candidates
- Must ask at least one question before next guess
- Go back to step 3 (Question Selection)

### 8. Game End
**Successful:** Place identified correctly  
**Failed:** Max questions reached, no candidates left  
**Display:** Game stats, correct place, learning summary

## State Machine

```
IDLE
  ↓ (user enters description)
START_GAME
  ↓ (fetch initial candidates)
FETCHING_CANDIDATES
  ↓ (candidates received)
READY_TO_GUESS or ASKING_QUESTION
  ↓ (based on confidence/questions)

READY_TO_GUESS
  ↓ (user confirms)
FINALIZING (correct) → COMPLETED
  ↓ (user rejects)
ASKING_QUESTION

ASKING_QUESTION
  ↓ (user answers)
ANSWERING_QUESTION
  ↓ (answer processed)
FETCHING_CANDIDATES
  ↓ (repeat)
```

## Game Parameters

**Configurable Values:**
```typescript
const MAX_QUESTIONS = 5           // Maximum questions per game
const MIN_CONFIDENCE = 0.7        // Threshold for immediate guess
const MIN_CANDIDATES = 3          // Minimum before guessing
const INITIAL_CANDIDATES = 20     // Vector similarity limit
const LEARNING_RATE = 0.1         // Place embedding update rate
const QUESTION_LEARNING_RATE = 0.2 // Question effectiveness update rate
```

**Effectiveness Calculation:**
```typescript
// Positive: Question narrowed candidates and kept target
// Negative: Question eliminated target or didn't narrow
const effectiveness_delta = 
  (narrowed_candidates ? 0.1 : -0.05) +
  (kept_target ? 0 : -0.15)

effectiveness_score = CLAMP(
  effectiveness_score + LEARNING_RATE * effectiveness_delta,
  0.0, 1.0
)
```

## Security & Permissions

**RLS Policies:**
```sql
-- game_sessions: Users access only their own
CREATE POLICY "Users can view own sessions" ON game_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own sessions" ON game_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- game_answers: Users access only their own
CREATE POLICY "Users can view own answers" ON game_answers
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM game_sessions WHERE user_id = auth.uid()
    )
  );
```

## Error Handling

**Frontend Error Cases:**
```typescript
// Embedding generation fails
if (!embedding) {
  toast.error('Failed to analyze description', {
    description: 'Please try again'
  })
  return
}

// No candidates found
if (topCandidates.value.length === 0) {
  toast.error('No matching places found', {
    description: 'Try a different description'
  })
}

// Database error
if (error) {
  console.error('Database error:', error)
  toast.error('Something went wrong', {
    description: 'Please refresh and try again'
  })
}
```

## Performance Considerations

**Optimizations:**
- Cache embeddings (never regenerate)
- Limit vector similarity to top 20
- Use HNSW indexing for vector search
- Debounce user input
- Lazy load map components
- Batch question effectiveness updates

**Database Indexes:**
```sql
-- Vector similarity (HNSW)
CREATE INDEX idx_places_embedding ON places 
USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_questions_embedding ON questions 
USING hnsw (embedding vector_cosine_ops);

-- Foreign keys
CREATE INDEX idx_game_answers_session_id ON game_answers(session_id);
CREATE INDEX idx_game_sessions_user_id ON game_sessions(user_id);
```

## Testing Strategy

**Unit Tests:**
- Game state transitions
- Candidate filtering logic
- Confidence calculations
- Answer validation

**Database Tests:**
- `get_candidates()` correctness
- Geographic filtering (PostGIS)
- Semantic filtering (pgvector)
- Wrong guess elimination
- Question effectiveness updates

**E2E Tests:**
- Complete game flow
- Correct guess flow
- Wrong guess flow
- Max questions reached
- No candidates remaining

## Future Enhancements

**Phase 2: Rich Embeddings**
- Add location context to embeddings
- Include Wikipedia descriptions
- Add materials, age, function

**Phase 3: Question Embeddings**
- Generate embeddings for all questions
- Enable semantic matching for geographic questions

**Phase 4: Advanced Learning**
- Personalized question selection
- User-specific confidence thresholds
- Adaptive learning rates

**Phase 5: Multiplayer**
- Competitive mode
- Cooperative mode
- Global leaderboards