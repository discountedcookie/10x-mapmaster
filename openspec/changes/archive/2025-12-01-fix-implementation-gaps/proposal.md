# Change: Fix Implementation Gaps

## Why

The game was not playable due to multiple implementation bugs:

1. Table name mismatches between code and schema (`place_traits` vs `traits`)
2. Question selection used LLM instead of algorithmic split_quality (per docs)
3. Frontend game store had incorrect response handling

## What Changes

### Database Fixes

- **Table name mismatches**: Fixed references in 5 SQL files:
  - `get_llm_question.sql`: `place_traits` → `traits` (for trait definitions)
  - `adjust_candidates_for_answer.sql`: `place_trait_links` → `place_traits`
  - `regenerate_place_traits.sql`: Fixed both table references
  - `get_semantic_questions.sql`: Fixed both table references
  - `submit_place.sql`: Fixed both table references
- **Question selection**: Changed `get_question()` to use `select_best_question()` instead of `get_llm_question()` per docs/architecture/algorithm.md ("Selection is deterministic and algorithmic")

### Frontend Fixes

- `start_game` response handling: RPC returns UUID directly, not array
- `play_turn` call: Pass enum `'yes'|'no'|'not_sure'`, not boolean
- `submitActualPlace`: Use `submit_place` RPC, not non-existent `add_place`
- Column name: `description_language_code` → `language_code`

## Impact

- Affected specs: algorithm, game-core, database
- Affected code: supabase/db/game_logic/functions/, src/stores/game.ts
- Game is now fully playable end-to-end
