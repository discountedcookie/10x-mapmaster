## 1. Behavior Specification

- [ ] 1.1 Add a `Statistics` (or similar) requirement to `openspec/specs/game-core/spec.md` describing what statistics the system must expose to players.
- [ ] 1.2 Extend `openspec/specs/database/spec.md` to document the stats view (e.g., `game_session_stats`), including columns like games played, won, lost, total questions, and any relevant timestamps.
- [ ] 1.3 Extend `openspec/specs/frontend/spec.md` to describe the `StatisticsView` route, its loading/error/empty states, and the metrics it displays.

## 2. Alignment with Implementation

- [ ] 2.1 Compare `useStatistics.ts` behavior with the new spec and adjust scenarios or wording if needed.
- [ ] 2.2 Verify that `StatisticsView.vue` handles all specified states (loading, error, no games, statistics shown).

## 3. Tests

- [ ] 3.1 Ensure `src/__tests__/composables/useStatistics.spec.ts` covers the spec scenarios.
- [ ] 3.2 Add or update tests for `StatisticsView.vue` if any coverage gaps remain.
