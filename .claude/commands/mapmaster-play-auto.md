# MapMaster Play - Automated Mode

Run an automated test game session for MapMaster using only Supabase MCP tools.

## Context

**Test User UUID:** `e5335fd5-348d-4047-9a9e-241e49bc01b8`

**Game Constants:**
- Max questions per game: 5
- Min confidence for guess: 0.7
- Vector dimensions: 384 (gte-small model)

## Database Functions

```sql
-- Get filtered candidates for a session
SELECT * FROM get_candidates(session_id UUID);
-- Returns: id, name, lat, lng, descriptors, semantic_similarity, spatial_confidence, composite_confidence

-- Get next question for a session
SELECT * FROM get_next_question(session_id UUID, match_count INT DEFAULT 10);
-- Returns: id, text, question_type, geographic_region, times_asked, effectiveness_score, semantic_similarity

-- Update question effectiveness (call after correct guess)
SELECT update_question_effectiveness_batch(session_id UUID);

-- Update place embedding (call after correct guess)
SELECT update_place_embedding(place_id UUID, embedding vector(384), learning_rate FLOAT DEFAULT 0.3);
```

## Edge Function

**Name:** `generate-embedding`
**Input:** `{"text": "description string"}`
**Output:** `{"embedding": [384 float values]}`

## Instructions

You are an AI agent testing the MapMaster game. Follow this workflow:

### Phase 1: Setup

1. **Create temporary table for embedding storage:**
```sql
CREATE TEMP TABLE IF NOT EXISTS agent_embeddings (
  id SERIAL PRIMARY KEY,
  embedding vector(384),
  description text,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

2. **Generate embedding for the place description:**
   - Use terminal to call the edge function with curl:
```bash
curl -X POST "https://[SUPABASE_PROJECT_REF].supabase.co/functions/v1/generate-embedding" \
  -H "Authorization: Bearer [ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{"text": "description here"}'
```
   - Extract the embedding array from response
   - **IMPORTANT:** Do NOT print the full 384-dimensional array. Only show first 3 and last 3 values like: `[0.123, -0.456, 0.789, ..., 0.234, -0.567, 0.890]`

3. **Store embedding in temp table:**
```sql
INSERT INTO agent_embeddings (embedding, description)
VALUES ('[0.123, -0.456, ...]'::vector(384), 'description text');
```

4. **Create game session:**
```sql
INSERT INTO game_sessions (user_id, description, description_embedding, created_at)
VALUES (
  'e5335fd5-348d-4047-9a9e-241e49bc01b8',
  'description text',
  (SELECT embedding FROM agent_embeddings ORDER BY id DESC LIMIT 1),
  NOW()
)
RETURNING id, description, created_at;
```
   - Store the returned session `id` for all subsequent calls

### Phase 2: Game Loop

Repeat until you make a guess:

1. **Get current candidates:**
```sql
SELECT * FROM get_candidates('session-id-here');
```
   - Display top 5 candidates with their confidence scores
   - Note the top candidate's composite_confidence

2. **Decide whether to guess or ask question:**
   - If top confidence >= 0.7 AND you've asked at least 1 question → proceed to Phase 3 (Guess)
   - If questions asked >= 5 → proceed to Phase 3 (Guess)
   - If candidates count = 0 → end game (no valid candidates)
   - Otherwise → ask a question

3. **Get next question:**
```sql
SELECT * FROM get_next_question('session-id-here', 10);
```
   - Display top 3 questions ranked by effectiveness_score and semantic_similarity

4. **Automatically answer the question:**
   - Use your knowledge to determine the correct answer
   - For the scenario description provided, reason about what the answer should be
   - Example: If description is "Tall iron tower in Paris" and question is "Is it in Europe?", answer YES
   - Example: If question is "Is it a natural feature?", answer NO for man-made structures

5. **Record the answer:**
```sql
-- First, count existing answers to get sequence number
SELECT COUNT(*) as seq_num FROM game_answers 
WHERE session_id = 'session-id-here' AND answer_type = 'question_answer';

-- Then insert the answer (increment seq_num by 1)
INSERT INTO game_answers (
  session_id, 
  question_id, 
  answer, 
  answer_type, 
  sequence_number,
  created_at
)
VALUES (
  'session-id-here',
  'question-id-here',
  true, -- or false based on your reasoning
  'question_answer',
  1, -- use seq_num + 1
  NOW()
);
```

6. **Display your reasoning:**
   - Show which question you answered
   - Show whether you answered YES or NO
   - Briefly explain why (1 sentence)

7. **Loop back to step 1**

### Phase 3: Make Guess

1. **Get final candidates:**
```sql
SELECT * FROM get_candidates('session-id-here') LIMIT 1;
```

2. **Display your guess:**
   - Show the place name and confidence score
   - Show total questions asked
   - Show reasoning for why this is the correct place

3. **Automatically determine if guess is correct:**
   - Based on the scenario description and your knowledge
   - For well-known places (Eiffel Tower, Statue of Liberty, etc.), you can determine correctness
   - For unknown places or ambiguous scenarios, assume correct if confidence > 0.6

4. **Finalize the session:**

**If guess is correct:**
```sql
-- Update session with correct guess
UPDATE game_sessions 
SET 
  place_id = 'place-id-here',
  was_correct = true,
  updated_at = NOW()
WHERE id = 'session-id-here';

-- Update question effectiveness
SELECT update_question_effectiveness_batch('session-id-here');

-- Update place embedding with learning
SELECT update_place_embedding(
  'place-id-here'::uuid,
  (SELECT embedding FROM agent_embeddings ORDER BY id DESC LIMIT 1),
  0.1
);
```

**If guess is wrong (for testing wrong guess flow):**
```sql
-- Get sequence number for wrong guess
SELECT COUNT(*) as seq_num FROM game_answers WHERE session_id = 'session-id-here';

-- Record wrong guess
INSERT INTO game_answers (
  session_id,
  place_id,
  answer_type,
  sequence_number,
  created_at
)
VALUES (
  'session-id-here',
  'wrong-place-id-here',
  'wrong_guess',
  seq_num + 1,
  NOW()
);

-- Then loop back to Phase 2 and continue
```

### Phase 4: Report Results

Display a comprehensive summary:

```markdown
## Game Session Results

**Session ID:** [uuid]
**Description:** "[user's description]"
**Scenario Type:** [e.g., "Happy path", "Not in database", "Wrong guess recovery"]

### Progression

1. **Initial candidates:** [count] places
   - Top 3: [name] (conf: X.XX), [name] (conf: X.XX), [name] (conf: X.XX)

2. **Question 1:** "[question text]"
   - Answer: [YES/NO]
   - Reasoning: [1 sentence]
   - Candidates after: [count]
   - Top confidence: X.XX

[Repeat for each question]

### Final Guess

**Place:** [place name]
**Confidence:** X.XX
**Correct:** [true/false]
**Total Questions:** X/5

### Learning Updates
- Question effectiveness scores updated: [true/false]
- Place embedding updated: [true/false]

### Statistics
- Questions asked: X
- Wrong guesses: X
- Candidates narrowed: [initial] → [final]
- Success: [✓/✗]
```

### Phase 5: Cleanup & Prompt

1. **Drop temporary table:**
```sql
DROP TABLE IF EXISTS agent_embeddings;
```

2. **Ask user:**
```
Would you like me to run another test game? If yes, please provide a scenario description or type 'random' for me to choose one.
```

## Scenario Examples

Use these as references for automated reasoning:

### Happy Path Scenarios
- **"Tall iron tower in Paris France"** → Eiffel Tower
  - Should answer YES to: Europe, France, man-made, tower, capital city, famous
  - Should answer NO to: natural feature, Asia, bridge

- **"Ancient amphitheater in Rome Italy"** → Colosseum
  - Should answer YES to: Europe, Italy, ancient, man-made, capital city
  - Should answer NO to: natural feature, modern, tower

- **"Tall volcanic mountain in Japan"** → Mount Fuji
  - Should answer YES to: Asia, Japan, natural feature, mountain, tall
  - Should answer NO to: Europe, man-made, tower, capital city

### Not in Database Scenarios
- **"Small cafe in my hometown"** → Should find no good matches
  - Candidates will have low confidence (< 0.4)
  - Report: "No candidates found with sufficient confidence"

- **"My neighbor's red house"** → Should find no matches
  - End with: "Unable to identify - description too specific/not in database"

### Ambiguous Scenarios
- **"Famous mountain"** → Multiple candidates (Everest, Fuji, Matterhorn, etc.)
  - Will need multiple questions to narrow down
  - Geographic questions will be most effective

- **"Ancient structure in desert"** → Could be pyramids, Petra, etc.
  - Test geographic filtering (Egypt, Jordan, etc.)
  - Test semantic filtering (age, construction type)

### Wrong Guess Recovery
- **Start with:** "Famous structure in France"
- **First guess:** Arc de Triomphe
- **Reject it, continue:** Should ask more questions
- **Final guess:** Eiffel Tower (the actual target)

## Error Handling

**If edge function fails:**
- Retry once after 2 seconds
- If still fails, ask user: "Edge function unavailable. Please provide a pre-generated embedding or skip this test."

**If no candidates returned:**
- Report: "No candidates match the description. The place may not be in the database."
- End gracefully without forcing a guess

**If max questions reached:**
- Make best guess with top candidate
- Report low confidence if applicable

**If embedding wrong dimensions:**
- Error: "Embedding has [X] dimensions, expected 384. Please check edge function."

## Technical Notes

- Always use `mcp_supabase_execute_sql` for database operations
- Use `run_terminal_cmd` for edge function invocation
- Store session_id in a variable, reuse it in all queries
- Count sequence_number before each answer insertion
- Only show embedding summary (first 3 + last 3 values), never the full array
- Use NOW() for timestamps instead of relying on database defaults
- Verify UUIDs are valid format before inserting

## Success Criteria

A successful test should:
1. ✓ Generate valid 384-dimensional embedding
2. ✓ Create game session with embedding
3. ✓ Retrieve and display candidates with confidence scores
4. ✓ Ask contextually relevant questions
5. ✓ Correctly reason about answers (for known places)
6. ✓ Make a guess when appropriate
7. ✓ Update learning functions on correct guess
8. ✓ Provide comprehensive results summary
9. ✓ Clean up temporary resources
10. ✓ Prompt user for next action

Good luck testing MapMaster! 🗺️

