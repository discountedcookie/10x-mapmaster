## 1. Remove Frontend Dead Code

- [x] 1.1 Delete `src/composables/game/useGameState.ts`
- [x] 1.2 Remove `renderMode` prop from `src/views/LoginView.vue`
- [x] 1.3 Remove `renderMode` prop from `src/views/SignupView.vue`
- [x] 1.4 Remove `renderMode` prop from `src/views/StatisticsView.vue`
- [x] 1.5 Remove associated eslint-disable comments for unused vars

## 2. Remove Database Dead Code

- [x] 2.1 Delete `supabase/db/game_logic/functions/apply_answer_to_session_state.sql`
- [x] 2.2 Delete `supabase/db/game_logic/functions/places/deduplicate_places.sql` (osm_id UNIQUE constraint makes this function useless)
- [x] 2.3 Remove any references to deleted functions in other SQL files
- [x] 2.4 Update migration build script if needed
- [x] 2.5 Delete `supabase/db/game_logic/functions/maintenance/maintenance_weekly.sql` (became dead after deduplicate_places removal)

## 3. Verify

- [x] 3.1 Run `bun run type-check` to ensure no broken imports
- [x] 3.2 Run `bun run db:rebuild` to verify database builds
- [x] 3.3 Run `bun run test:db` to verify database tests pass
- [x] 3.4 Run `bun run test` to verify all tests pass
