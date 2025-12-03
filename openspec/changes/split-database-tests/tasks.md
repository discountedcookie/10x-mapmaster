# Tasks: split-database-tests

## 1. Create Table Domain Test Files

- [x] 1.1 Create `test_tables_places.sql` with places schema + RLS tests
- [x] 1.2 Create `test_tables_traits.sql` with traits schema + RLS tests
- [x] 1.3 Create `test_tables_place_traits.sql` with place_traits schema + RLS tests
- [x] 1.4 Create `test_tables_game_sessions.sql` with game_sessions schema + RLS + ownership tests
- [x] 1.5 Create `test_tables_game_answers.sql` with game_answers schema + RLS tests
- [x] 1.6 Create `test_tables_embeddings.sql` with embeddings schema + RLS tests
- [x] 1.7 Create `test_tables_geographic_regions.sql` with geographic_regions schema + RLS tests
- [x] 1.8 Create `test_tables_config.sql` with config tables schema + RLS + behavior tests

## 2. Create View Domain Test Files

- [x] 2.1 Create `test_views_game_session_state.sql` with view access tests
- [x] 2.2 Create `test_views_user_stats.sql` with user_stats view tests
- [x] 2.3 Create `test_views_global_stats.sql` with global_stats view tests

## 3. Create Function Domain Test Files

- [x] 3.1 Rename/migrate algorithm tests to `test_functions_algorithm.sql`
- [x] 3.2 Create `test_functions_play_turn.sql` from game_basics + geographic tests
- [x] 3.3 Create `test_functions_start_game.sql` from game_basics tests
- [x] 3.4 Create `test_functions_questions.sql` from geographic_filtering tests

## 4. Create Schema Infrastructure Test File

- [x] 4.1 Create `test_schema.sql` with extensions, types, triggers tests

## 5. Delete Original Test Files

- [x] 5.1 Delete `test_algorithm_functions.sql` (migrated to test_functions_algorithm.sql)
- [x] 5.2 Delete `test_game_basics.sql` (migrated to test*functions*\*)
- [x] 5.3 Delete `test_geographic_filtering.sql` (migrated to test_functions_questions.sql)
- [x] 5.4 Delete `test_rls_policies.sql` (migrated to test*tables*\*)
- [x] 5.5 Delete `test_schema_validation.sql` (migrated to domain files + test_schema.sql)
- [x] 5.6 Delete `test_settings_control_behavior.sql` (migrated to test_tables_config.sql)

## 6. Verify and Update Specs

- [x] 6.1 Run all tests to verify migration correctness
- [x] 6.2 Update database spec with test organization conventions
