---
name: gameplay-sql
description: >-
  Test game mechanics via SQL. Use psql to call start_game(), play_turn(),
  and check game_session_state view.
---

# SQL Gameplay

Test game logic directly via SQL without UI.

> **Announce:** "I'm using gameplay-sql to test via database."

## Connect

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
```

## Auth Setup (Required)

```sql
SET request.jwt.claim.sub = 'a1b2c3d4-e5f6-4321-abcd-1234567890ab';
SET request.jwt.claim.role = 'authenticated';
SET ROLE authenticated;
```

## Game Flow

```sql
-- 1. Start game
SELECT start_game('A famous tower in Paris', 'en');
-- Returns session_id UUID

-- 2. Check state
SELECT status, question->>'text', guess->>'place_name'
FROM game_session_state WHERE session_id = 'SESSION_ID';

-- 3. Answer question or confirm/deny guess
SELECT play_turn('SESSION_ID'::uuid, 'yes'::answer_value);
-- Answers: 'yes', 'no', 'not_sure'

-- 4. If status = 'needs_submission', submit correct place
SELECT submit_place('SESSION_ID'::uuid, 'way/5013364');
```

## Key Views/Functions

| Function | Purpose |
|----------|---------|
| `start_game(description, lang)` | Start new game, returns session_id |
| `play_turn(session_id, answer)` | Answer question or confirm/deny guess |
| `submit_place(session_id, osm_id)` | Submit correct place when giving up |
| `game_session_state` view | Current game state with candidates |

## Common Issues

- **"Authentication required"** → Run auth setup commands first
- **`auth.uid()` returns NULL** → Missing `SET ROLE authenticated`
- **Empty results** → RLS filtering, check auth.uid() matches user_id
