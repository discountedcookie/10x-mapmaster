# Change: Game Core

## Why

With the database foundation and algorithm engine in place, we need the orchestration functions that power gameplay: `start_game`, `play_turn`, `submit_place`, learning triggers, and cleanup jobs. These functions own the state machine described in `spec/gameplay.md`.

## Scope

- RPC functions (`start_game`, `play_turn`, `submit_place`)
- Turn processing helpers (record answers, build questions/guesses)
- Learning pipeline (regenerate traits, update embeddings)
- Session lifecycle (needs_submission → ended, abandoned cleanup)

## Impact

- Enables frontend to play real games end-to-end
- Unlocks statistics/history views
- Ensures learning loop improves accuracy over time

## Success Criteria

- Supabase RPC endpoints callable from frontend (types generated)
- pgTAP tests for happy path and failure cases
- Cron cleanup job removes abandoned sessions
- Learning trigger regenerates traits for approved sessions
