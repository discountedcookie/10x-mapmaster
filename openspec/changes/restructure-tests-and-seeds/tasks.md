## Phase 1: Create Data Directory Structure

- [ ] 1.1 Create `supabase/db/game_logic/data/` directory
- [ ] 1.2 Extract game config from `seeds/00_static_data.sql` to `data/config.sql` (exclude runtime.\* keys)
- [ ] 1.3 Move `seeds/02_geographic_regions.sql` to `data/geographic_regions.sql`
- [ ] 1.4 Update `scripts/generate-geographic-regions.ts` to output to new location

## Phase 2: Restructure Seeds

- [ ] 2.1 Create `seeds/00_dev_runtime.sql` with runtime.\* keys only
- [ ] 2.2 Create `seeds/01_dev_users.sql` with test users only
- [ ] 2.3 Rename `seeds/01_embedding_data.sql` to `seeds/02_dev_data.sql`
- [ ] 2.4 Delete old `seeds/00_static_data.sql` and `seeds/02_geographic_regions.sql`

## Phase 3: Consolidate DB Tests by Domain

- [ ] 3.1 Create `tests/test_game_flow.sql` combining start_game + play_turn tests
- [ ] 3.2 Create `tests/test_places.sql` with places RLS + submit_place tests
- [ ] 3.3 Create `tests/test_sessions.sql` with sessions/answers RLS tests
- [ ] 3.4 Keep `tests/test_functions_algorithm.sql` (rename to `test_algorithm.sql`)

## Phase 4: Delete Structural Tests

- [ ] 4.1 Delete `test_schema.sql`
- [ ] 4.2 Delete `test_tables_config.sql`
- [ ] 4.3 Delete `test_tables_embeddings.sql`
- [ ] 4.4 Delete `test_tables_game_answers.sql`
- [ ] 4.5 Delete `test_tables_game_sessions.sql`
- [ ] 4.6 Delete `test_tables_geographic_regions.sql`
- [ ] 4.7 Delete `test_tables_place_traits.sql`
- [ ] 4.8 Delete `test_tables_places.sql`
- [ ] 4.9 Delete `test_tables_traits.sql`
- [ ] 4.10 Delete `test_views_game_session_state.sql`
- [ ] 4.11 Delete `test_views_global_stats.sql`
- [ ] 4.12 Delete `test_views_user_stats.sql`
- [ ] 4.13 Delete old `test_functions_start_game.sql` and `test_functions_play_turn.sql` (consolidated)

## Phase 5: Trim Frontend Tests

- [ ] 5.1 Delete `src/__tests__/stores/game.spec.ts` (mocks everything)
- [ ] 5.2 Delete `src/__tests__/composables/useStatistics.spec.ts` (mocks everything)
- [ ] 5.3 Trim `src/__tests__/stores/places.spec.ts` to keep only pure logic tests
- [ ] 5.4 Review and trim `src/__tests__/components/` if needed

## Phase 6: Cleanup and Verify

- [ ] 6.1 Delete orphaned `src/composables/game/useGameState.ts` (references deleted components)
- [ ] 6.2 Run `bun run db:rebuild`
- [ ] 6.3 Run `bun run test:db` - verify all DB tests pass
- [ ] 6.4 Run `bun run test:unit` - verify remaining unit tests pass
- [ ] 6.5 Run `bun run type-check` - verify no type errors
