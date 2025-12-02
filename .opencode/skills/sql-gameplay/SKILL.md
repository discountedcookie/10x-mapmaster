---
name: sql-gameplay
description: >-
  Use when testing game behavior via SQL directly. Invoke start_game() and 
  play_turn() functions through psql to verify game mechanics without UI.
  Useful for debugging and validating database-level game logic.
---

# SQL Gameplay Testing

Test game mechanics directly via SQL without needing the UI.

> **Announce:** "I'm using sql-gameplay to test game behavior via SQL."

## When to Use

- Debugging game logic issues
- Verifying scoring/ranking algorithms work
- Testing edge cases in game flow
- Validating RLS policies
- Testing without frontend running

## Prerequisites

Supabase must be running:
```bash
supabase status  # Check if running
supabase start -x vector  # Start if needed
```

## Connect to Database

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
```

## Game Flow via SQL

### 1. Setup Auth Context

**Important:** Set role and claim for `auth.uid()` to work:

```sql
SET request.jwt.claim.sub = 'a1b2c3d4-e5f6-4321-abcd-1234567890ab';
SET request.jwt.claim.role = 'authenticated';
SET ROLE authenticated;

-- Verify it works
SELECT auth.uid();
```

### 2. Start a Game

```sql
-- Start with description and optional language code
SELECT start_game('A famous tower in Paris', 'en');
-- Returns: session_id (UUID)
```

Save the returned `session_id` for subsequent calls.

### 3. Check Game State

Use `game_session_state` view (requires auth context in same connection):

```sql
SELECT 
  status,
  question->>'text' as question_text,
  guess->>'place_name' as guess_name,
  jsonb_array_length(candidates) as candidate_count,
  question_count
FROM game_session_state 
WHERE session_id = 'YOUR_SESSION_ID';
```

View columns:
- `session_id` - Game UUID
- `description` - User's original description
- `status` - 'active', 'won', 'ended', 'needs_submission'
- `question` - JSONB `{text}` when asking a question (NULL during guess)
- `guess` - JSONB `{place_id, place_name}` when making a guess (NULL during question)
- `place` - JSONB `{id, name, lat, lng}` when game ends
- `candidates` - JSONB array of candidate places with confidence scores
- `question_count` - Number of questions asked

Or query `game_sessions` directly for raw `next_turn`:

```sql
SELECT 
  next_turn->>'action' as action,
  next_turn->>'question_text' as question_text,
  next_turn->>'place_name' as guess_name
FROM game_sessions 
WHERE id = 'YOUR_SESSION_ID';
```

### 4. Answer a Question

```sql
SELECT play_turn('YOUR_SESSION_ID', 'yes');
SELECT play_turn('YOUR_SESSION_ID', 'no');
SELECT play_turn('YOUR_SESSION_ID', 'not_sure');
```

### 5. Handle a Guess

When `status = 'active'` and `guess IS NOT NULL`:

```sql
-- Confirm the guess is correct
SELECT play_turn('YOUR_SESSION_ID', 'yes');

-- Deny the guess
SELECT play_turn('YOUR_SESSION_ID', 'no');
```

### 6. Submit Correct Place (Give Up)

When `status = 'needs_submission'`:

```sql
-- Submit using OSM ID (e.g., way/5013364 for Eiffel Tower)
SELECT submit_place('YOUR_SESSION_ID'::uuid, 'way/5013364');
```

This fetches place data from Nominatim, extracts traits via LLM, generates embeddings, and ends the game.

## Full Example Session

```sql
-- Setup auth (MUST be in same psql session)
SET request.jwt.claim.sub = 'a1b2c3d4-e5f6-4321-abcd-1234567890ab';
SET request.jwt.claim.role = 'authenticated';
SET ROLE authenticated;

-- Start game
SELECT start_game('A tall tower');
-- Returns: session_id UUID

-- Check state (question or guess will be populated, not both)
SELECT 
  status,
  jsonb_array_length(candidates) as candidate_count,
  question->>'text' as question_text,
  guess->>'place_name' as guess_name
FROM game_session_state 
WHERE session_id = 'YOUR_SESSION_ID';

-- Answer question or confirm/deny guess
SELECT play_turn('YOUR_SESSION_ID'::uuid, 'yes'::answer_value);
-- or 'no'::answer_value, 'not_sure'::answer_value

-- Continue until status = 'won' or 'needs_submission'
-- If needs_submission, submit the correct place:
SELECT submit_place('YOUR_SESSION_ID'::uuid, 'way/5013364');
```

## Debugging Tips

### View Candidates with Scores

```sql
SELECT 
  c->>'name' as place,
  (c->>'confidence')::numeric as confidence
FROM game_session_state,
     jsonb_array_elements(candidates) as c
WHERE session_id = 'YOUR_SESSION_ID'
ORDER BY confidence DESC
LIMIT 5;
```

### View Answer History

```sql
SELECT 
  ga.answer,
  t.clause as trait,
  gr.name as region
FROM game_answers ga
LEFT JOIN traits t ON ga.trait_id = t.id
LEFT JOIN geographic_regions gr ON ga.geographic_region_id = gr.id
WHERE ga.session_id = 'YOUR_SESSION_ID'
ORDER BY ga.created_at;
```

### Check Raw next_turn

```sql
SELECT jsonb_pretty(next_turn)
FROM game_sessions 
WHERE id = 'YOUR_SESSION_ID';
```

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Authentication required" | Missing JWT context | Set `request.jwt.claim.sub`, `request.jwt.claim.role`, and `SET ROLE authenticated` |
| `auth.uid()` returns NULL | Missing role setting | Ensure `SET ROLE authenticated` is called |
| "no_candidates" in next_turn | No matching places found | Check embeddings exist, may need to regenerate with current model |
| Empty game_session_state | RLS filtering | Ensure auth.uid() matches session's user_id |
| Function not found | Missing type cast | Cast UUID explicitly: `'...'::uuid`, answer: `'yes'::answer_value` |

## When to Use Other Skills

- For automated testing → Use `test-tdd` with pgTAP
- For debugging failures → Use `systematic-debugging`
- For full flow testing → Dispatch `@player` agent with Chrome DevTools
