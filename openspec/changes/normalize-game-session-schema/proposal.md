# Change: Normalize Game Session Schema

## Why

The current game session architecture stores dynamic state in a `next_turn` JSONB column:

```sql
-- Current: JSONB with dynamic shapes
next_turn JSONB -- Contains question OR guess data + candidates array
```

This causes problems:

1. **No type safety** - Supabase generates `Json` type, forcing manual TypeScript definitions
2. **Frontend casts everywhere** - `as unknown as { question: ... }` throughout codebase
3. **Schema not self-documenting** - Shape lives in code comments, not database constraints
4. **Can't query/index JSONB internals efficiently**

The `game_session_state` view extracts JSONB into more JSONB blobs (`question`, `guess`, `candidates`), which doesn't solve the typing problem.

## What Changes

**Add two new tables:**

1. **`game_turn`** - Current pending action (what we're asking the user)
   - 1:1 with `game_sessions`
   - Contains: action type, question fields, guess fields
   - Row exists = game has pending turn; no row = game ended

2. **`game_session_candidates`** - Current candidate places with scores
   - N:1 with `game_sessions`
   - Contains: place_id, probability, similarity scores
   - Replaces candidates array in JSONB

**Modify existing:**

- **`game_sessions`** - Remove `next_turn` JSONB column
- **`game_session_state`** - Flatten to typed columns (no JSONB output)
- **Game logic functions** - Update to use new tables instead of JSONB

**Result:**

| Table                     | Purpose                                                        |
| ------------------------- | -------------------------------------------------------------- |
| `game_sessions`           | Session lifecycle (id, user, description, status, final place) |
| `game_turn`               | Current pending action (question or guess being asked)         |
| `game_answers`            | History of past turns (what was asked, what user answered)     |
| `game_session_candidates` | Current candidate places with scores                           |

All game state is now:

- Properly relational
- Fully typed by Supabase
- Queryable and indexable
- Self-documenting via schema

## Impact

- Affected specs: `database`, `game-core`, `frontend`
- Affected code:
  - `supabase/db/public/` - Schema changes, view rewrite
  - `supabase/db/game_logic/` - All game logic functions
  - `supabase/migrations/` - New migration
  - `src/stores/gameSession.ts` - Use typed columns
  - `src/composables/game/useGameMap.ts` - Use typed candidates
  - `src/components/game/states/` - Use typed data
  - `src/lib/api/index.ts` - Typed return from `play_turn`
