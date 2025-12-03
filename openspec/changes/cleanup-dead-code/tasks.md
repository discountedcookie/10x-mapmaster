## 1. Remove Frontend Dead Code

- [ ] 1.1 Delete `src/composables/game/useGameState.ts`
- [ ] 1.2 Remove `renderMode` prop from `src/views/LoginView.vue`
- [ ] 1.3 Remove `renderMode` prop from `src/views/SignupView.vue`
- [ ] 1.4 Remove `renderMode` prop from `src/views/StatisticsView.vue`
- [ ] 1.5 Remove associated eslint-disable comments for unused vars

## 2. Remove Database Dead Code

- [ ] 2.1 Delete `supabase/db/game_logic/functions/apply_answer_to_session_state.sql`
- [ ] 2.2 Remove any references to the function in other SQL files
- [ ] 2.3 Update migration build script if needed

## 3. Verify

- [ ] 3.1 Run `bun run type-check` to ensure no broken imports
- [ ] 3.2 Run `bun run db:rebuild` to verify database builds
- [ ] 3.3 Run `bun run test` to verify all tests pass
