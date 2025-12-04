# Change: Normalize Game Session Schema

## Why

The current game session architecture has two problems:

1. **JSONB everywhere** - `next_turn` JSONB column forces manual TypeScript definitions and `as unknown as` casts throughout the frontend
2. **No turn history for UI** - Frontend needs to show "how the game progressed" after completion, but `game_answers.candidates` is JSONB and not designed for presentation

## What Changes

**Add two new tables:**

1. **`game_turns`** - All turns (historical + current pending)
   - Multiple rows per session (turn history)
   - Contains: turn_number, action type, question/guess fields, answer (NULL = pending)
   - Frontend can replay the game after completion

2. **`game_turn_candidates`** - Candidates at each turn
   - FK to `game_turns.id` (not session)
   - Contains: place_id, probability, similarity scores
   - Typed history, not JSONB snapshots

**Remove:**

- **`game_sessions.next_turn`** - JSONB column (replaced by `game_turns`)
- **`game_answers`** - Table (replaced by `game_turns`)

**Rename:**

- **`game_session_state`** → **`game_state`** - Cleaner name

**Result:**

| Table                  | Purpose                                            |
| ---------------------- | -------------------------------------------------- |
| `game_sessions`        | Session lifecycle (id, user, description, outcome) |
| `game_turns`           | All turns with typed columns (history + pending)   |
| `game_turn_candidates` | Candidates at each turn (typed, queryable)         |
| `game_state` (view)    | Current state for frontend (flattened, typed)      |

All game state is now:

- Properly relational
- Fully typed by Supabase
- Queryable for both current state AND history
- No JSONB in frontend-facing APIs

## Impact

- Affected specs: `database`, `game-core`, `frontend`
- Affected code:
  - `supabase/db/public/` - Schema changes, view rename
  - `supabase/db/game_logic/` - All game logic functions
  - `supabase/migrations/` - New migration
  - `src/stores/gameSession.ts` - Use typed columns
  - `src/composables/game/useGameMap.ts` - Use typed candidates
  - `src/components/game/states/` - Use typed data
  - `src/lib/api/index.ts` - Typed returns, history API
