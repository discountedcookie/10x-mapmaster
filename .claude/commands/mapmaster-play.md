# MapMaster Play - Interactive Mode

Run an interactive test game session for MapMaster using only Supabase MCP tools. You'll be asked to answer questions and confirm guesses.

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

You are an AI agent facilitating an interactive MapMaster game test. Guide the user through the game flow by asking for their input at decision points.

### Phase 1: Setup

1. **Acknowledge the scenario:**
   - Display: "Starting MapMaster game session..."
   - Display: "Scenario: [scenario from user's command]"

2. **Create temporary table for embedding storage:**
```sql
CREATE TEMP TABLE IF NOT EXISTS agent_embeddings (
  id SERIAL PRIMARY KEY,
  embedding vector(384),
  description text,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

3. **Generate embedding for the place description:**
   - Use terminal to call the edge function with curl:
```bash
curl -X POST "https://[SUPABASE_PROJECT_REF].supabase.co/functions/v1/generate-embedding" \
  -H "Authorization: Bearer [ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{"text": "description here"}'
```
   - Display: "✓ Generated embedding for description"
   - **IMPORTANT:** Only show embedding summary: `[first 3 values, ..., last 3 values]`
   - Do NOT display all 384 values

4. **Store embedding in temp table:**
```sql
INSERT INTO agent_embeddings (embedding, description)
VALUES ('[0.123, -0.456, ...]'::vector(384), 'description text');
```

5. **Create game session:**
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
   - Display: "✓ Game session created: [session-id]"
   - Store the session `id` for all subsequent calls

### Phase 2: Game Loop

Repeat until user confirms a guess:

1. **Get current candidates:**
```sql
SELECT * FROM get_candidates('session-id-here') LIMIT 10;
```

2. **Display candidate status:**
```markdown
### Current Candidates ([count] places found)

Top 5 candidates:
1. **[place name]** - Confidence: X.XX (semantic: X.XX, spatial: X.XX)
   Location: [lat], [lng]
   Type: [descriptors->type]

2. [repeat for top 5]

[If count > 5] ... and [X] more candidates
```

3. **Decide whether to guess or ask question:**
```markdown
### Game State
- Questions asked: X/5
- Top confidence: X.XX
- Candidates: [count]

[If top confidence >= 0.7 AND questions >= 1]
**Option: Ready to make a guess! Should I present the top candidate?**

[If questions >= 5]
**Max questions reached. I'll present the best guess.**

[If candidates == 0]
**No candidates remaining. Game over.**

[Otherwise]
**I'll ask the next question...**
```

4. **Get next question:**
```sql
SELECT * FROM get_next_question('session-id-here', 10);
```

5. **Present question to user:**
```markdown
### Question [X]/5

**Question:** [question text]
**Type:** [question_type]
**Effectiveness Score:** X.XX
[If geographic] **Region:** [region name from geographic_region->name]

**Please answer:** YES or NO

[If question_type = 'geographic']
ℹ️ This question filters candidates geographically within: [region description]

[If question_type = 'semantic']  
ℹ️ This question uses semantic similarity to boost/penalize candidates
```

6. **Wait for user response:**
   - User must respond with "YES" or "NO" (case insensitive)
   - Validate response before proceeding

7. **Record the answer:**
```sql
-- Get sequence number
SELECT COUNT(*) as seq_num FROM game_answers 
WHERE session_id = 'session-id-here' AND answer_type = 'question_answer';

-- Insert answer (use seq_num + 1)
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
  true, -- user's answer converted to boolean
  'question_answer',
  [seq_num + 1],
  NOW()
);
```

8. **Confirm answer recorded:**
```markdown
✓ Recorded your answer: [YES/NO]
Fetching updated candidates...
```

9. **Loop back to step 1**

### Phase 3: Make Guess

1. **Get final candidates:**
```sql
SELECT * FROM get_candidates('session-id-here') LIMIT 1;
```

2. **Present guess to user:**
```markdown
### 🎯 My Guess

**Place:** [place name]
**Confidence:** X.XX
**Location:** [lat], [lng]
**Details:**
- Type: [descriptors->type]
- Class: [descriptors->class]
[Include any other relevant descriptors]

**Game Statistics:**
- Questions asked: X/5
- Initial candidates: [count from first fetch]
- Final candidates: [count from last fetch]
- Confidence progression: [initial top] → [final top]

---

**Is this guess CORRECT?**
Please respond with:
- "CORRECT" - if the guess matches your intended place
- "WRONG" - if this is not the right place (I'll continue playing)
- "UNSURE" - if you're not sure (I'll mark as correct for testing purposes)
```

3. **Wait for user response:**
   - User responds with CORRECT, WRONG, or UNSURE
   - Handle each case accordingly

4. **Handle user response:**

**If CORRECT or UNSURE:**
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

Display:
```markdown
✓ Correct! 🎉

**Learning Updates Applied:**
- Question effectiveness scores updated
- Place embedding updated with your description
- Game statistics recorded
```

Proceed to Phase 4.

**If WRONG:**
```sql
-- Get sequence number
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
  [seq_num + 1],
  NOW()
);
```

Display:
```markdown
Got it - that guess was wrong. Let me continue with more questions.
(This place has been eliminated from future guesses)
```

Loop back to Phase 2 (must ask at least one more question before guessing again).

### Phase 4: Report Results

Display a comprehensive summary:

```markdown
## 📊 Game Session Complete

**Session ID:** [uuid]
**Description:** "[user's description]"
**Scenario Type:** [from command]
**Duration:** [calculated from created_at to now]

---

### 🎮 Game Progression

#### Initial State
- **Candidates found:** [count] places
- **Top 3 initial candidates:**
  1. [name] - Confidence: X.XX
  2. [name] - Confidence: X.XX
  3. [name] - Confidence: X.XX

#### Question History

1. **Question:** "[text]"
   - **Type:** [question_type]
   - **Your Answer:** [YES/NO]
   - **Effect:** [count before] → [count after] candidates
   - **Top confidence:** X.XX → X.XX

[Repeat for each question]

[If any wrong guesses]
#### Wrong Guesses
1. **[place name]** (confidence: X.XX) - Rejected at question [X]

---

### 🎯 Final Result

**Correct Place:** [place name]
**Final Confidence:** X.XX
**Total Questions:** X/5
**Wrong Guesses:** X
**Status:** ✓ SUCCESS

---

### 📈 Performance Metrics

- **Candidate Narrowing:** [initial] → [final] (-X.X% reduction)
- **Confidence Improvement:** X.XX → X.XX (+X.X%)
- **Questions Efficiency:** X questions to identify place
- **Geographic Filtering:** [X] geographic questions asked
- **Semantic Filtering:** [X] semantic questions asked

---

### 🧠 Learning Applied

- ✓ Question effectiveness scores updated for [X] questions
- ✓ Place embedding updated with learning rate 0.1
- ✓ Game statistics recorded

---

### 🗄️ Database State

**Session record:**
```sql
SELECT id, description, was_correct, created_at, updated_at 
FROM game_sessions WHERE id = '[session-id]';
```

**Answer records:**
```sql
SELECT answer_type, sequence_number, answer, created_at 
FROM game_answers WHERE session_id = '[session-id]' 
ORDER BY sequence_number;
```
```

### Phase 5: Cleanup & Prompt

1. **Drop temporary table:**
```sql
DROP TABLE IF EXISTS agent_embeddings;
```

2. **Ask user:**
```markdown
---

## Continue Testing?

Would you like to run another test game? 

**Options:**
- Provide a new scenario description (e.g., "Test wrong guess recovery flow")
- Type **"random"** for me to choose a scenario
- Type **"done"** to end testing

What would you like to do?
```

## User Interaction Guidelines

### Question Answering
- Accept: "yes", "YES", "y", "Y", "true", "1" → true
- Accept: "no", "NO", "n", "N", "false", "0" → false
- Reject any other input and ask again

### Guess Confirmation
- Accept: "correct", "CORRECT", "yes", "right", "✓" → correct
- Accept: "wrong", "WRONG", "no", "incorrect", "✗" → wrong
- Accept: "unsure", "UNSURE", "maybe", "?" → treat as correct for testing

### Display Format
- Use markdown for clear formatting
- Use emojis sparingly (✓, ✗, 🎯, 📊, 🎮, 🧠, 🗄️)
- Show confidence scores rounded to 2 decimals
- Show candidate counts clearly
- Group related information in sections

## Scenario Examples

### Happy Path
```
/mapmaster-play Tall iron tower in Paris France
```
Expected: Eiffel Tower identified with high confidence

### Geographic Filtering Test
```
/mapmaster-play Famous mountain in Asia
```
Expected: Multiple questions to narrow region (Japan vs Nepal vs China)

### Wrong Guess Recovery
```
/mapmaster-play Famous structure in Rome Italy with arches
```
Expected: May guess Arc de Constantine first, user rejects, then guesses Colosseum

### Not in Database
```
/mapmaster-play Small cafe near my house
```
Expected: Low confidence candidates, graceful handling

### Ambiguous Description
```
/mapmaster-play Ancient religious building
```
Expected: Many questions needed, multiple candidates remain

## Error Handling

**If edge function fails:**
```markdown
❌ Edge function failed to generate embedding.
Retrying in 2 seconds...

[After retry]
❌ Still unable to generate embedding.

**Options:**
1. Try again with a different description
2. Skip this test
3. Check if Supabase edge functions are deployed

What would you like to do?
```

**If no candidates found:**
```markdown
⚠️ No candidates found matching the description.

**Possible reasons:**
- Place not in database (only 20 famous places seeded)
- Description too specific or unusual
- Embedding quality issue

**Current database includes:**
[Query and list 5 random place names from database]

Would you like to try a different description?
```

**If max questions reached without good confidence:**
```markdown
⚠️ Max questions (5) reached with low confidence (X.XX).

I'll make my best guess, but confidence is low. This may indicate:
- Place not in database
- Description doesn't match well
- More questions needed (increase MAX_QUESTIONS in database function)

Proceeding with best available guess...
```

**If invalid user input:**
```markdown
❌ Invalid response. Please respond with:
- For questions: YES or NO
- For guesses: CORRECT or WRONG
- For continuation: provide scenario or type "done"

Please try again:
```

## Technical Notes

- Always use `mcp_supabase_execute_sql` for database operations
- Use `run_terminal_cmd` for edge function invocation
- Store session_id in a variable for reuse across all queries
- Track question count to display X/5 progress
- Store initial candidate count for reporting
- Validate all user inputs before processing
- Use NOW() for timestamps
- Only display embedding summary, never full 384 values
- Format UUIDs correctly in SQL strings

## Success Criteria

A successful interactive test should:
1. ✓ Generate valid 384-dimensional embedding
2. ✓ Create game session with embedding
3. ✓ Display candidates clearly with confidence scores
4. ✓ Present relevant questions one at a time
5. ✓ Accept and validate user responses
6. ✓ Update game state after each answer
7. ✓ Present guess when appropriate
8. ✓ Handle user's guess confirmation
9. ✓ Apply learning updates on correct guess
10. ✓ Provide comprehensive final report
11. ✓ Clean up temporary resources
12. ✓ Prompt user for next action

## Differences from Automated Mode

- **User answers questions** instead of agent reasoning
- **More verbose display** of game state and candidates
- **Interactive confirmations** for guesses
- **Detailed explanations** of what each question does
- **User controls pacing** - agent waits for responses
- **Flexible continuation** - user decides next test

Good luck testing MapMaster! 🗺️🎮

