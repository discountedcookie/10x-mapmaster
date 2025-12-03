# Change: Specify Statistics View Capability

## Why

The system exposes a database statistics view and a `StatisticsView.vue` frontend overlay that summarizes user performance, but this capability is not fully captured in the specs. As a result, behavior, edge cases, and API contracts for statistics are under-documented.

## What Changes

- Add explicit requirements for the user statistics capability in the `game-core` and `frontend` specs.
- Document the underlying database view (e.g., `game_session_stats`) in the `database` spec, including inputs and outputs.
- Ensure existing `useStatistics` and `StatisticsView.vue` behavior is aligned with the new requirements.

## Impact

- Affected specs: `game-core`, `database`, `frontend`.
- Affected code (behavior only, no immediate changes): `supabase/db/public/views/*stats*`, `src/composables/useStatistics.ts`, `src/views/StatisticsView.vue`, and their tests.
- Makes the statistics feature a first-class, documented capability in the system.
