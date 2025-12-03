# Change: Cleanup Dead Code

## Why

The codebase contains several pieces of dead code from abandoned refactors:

1. `src/composables/game/useGameState.ts` - Duplicates logic in GameView.vue but is never imported
2. `supabase/db/game_logic/functions/apply_answer_to_session_state.sql` - Function body is a no-op (comment says "No session state update needed")
3. `renderMode` prop in LoginView, SignupView, StatisticsView - Defined but never used

Dead code creates confusion, maintenance burden, and false signals about architecture.

## What Changes

- Delete `useGameState.ts` composable
- Remove or properly implement `apply_answer_to_session_state` function
- Remove unused `renderMode` props from auth views

## Impact

- Affected specs: `frontend`, `database`
- Affected code:
  - `src/composables/game/useGameState.ts` - Delete
  - `src/views/LoginView.vue` - Remove prop
  - `src/views/SignupView.vue` - Remove prop
  - `src/views/StatisticsView.vue` - Remove prop
  - `supabase/db/game_logic/functions/apply_answer_to_session_state.sql` - Remove
