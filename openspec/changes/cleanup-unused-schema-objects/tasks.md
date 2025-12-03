# Tasks: cleanup-unused-schema-objects

## 1. Drop Unused Tables

- [ ] 1.1 Delete `supabase/db/public/tables/app_settings.sql`
- [ ] 1.2 Delete `supabase/db/public/tables/config.sql`
- [ ] 1.3 Delete `supabase/db/game_logic/tables/question_stats.sql`

## 2. Move Tables to game_logic Schema

- [ ] 2.1 Move `supabase/db/public/tables/embeddings.sql` to `supabase/db/game_logic/tables/embeddings.sql`
- [ ] 2.2 Update embeddings.sql: change schema from `public` to `game_logic`
- [ ] 2.3 Update embeddings.sql: update RLS policies for game_logic schema
- [ ] 2.4 Move `supabase/db/public/tables/geographic_regions.sql` to `supabase/db/game_logic/tables/geographic_regions.sql`
- [ ] 2.5 Update geographic_regions.sql: change schema from `public` to `game_logic`
- [ ] 2.6 Update geographic_regions.sql: update RLS policies for game_logic schema

## 3. Update Foreign Key References

- [ ] 3.1 Update `places.sql`: FK to embeddings now references `game_logic.embeddings`
- [ ] 3.2 Update `traits.sql`: FK to embeddings now references `game_logic.embeddings`
- [ ] 3.3 Update `game_sessions.sql`: FK to embeddings now references `game_logic.embeddings`
- [ ] 3.4 Update `game_answers.sql`: FK to geographic_regions now references `game_logic.geographic_regions`
- [ ] 3.5 Update `question_stats.sql` FK reference (before deletion) - N/A, deleting whole file

## 4. Drop Unused Algorithm Functions

- [ ] 4.1 Delete `supabase/db/game_logic/functions/algorithm/adjust_score.sql`
- [ ] 4.2 Delete `supabase/db/game_logic/functions/algorithm/calculate_split_quality.sql`
- [ ] 4.3 Delete `supabase/db/game_logic/functions/algorithm/filter_by_geography.sql`
- [ ] 4.4 Delete `supabase/db/game_logic/functions/algorithm/trait_match_strength.sql`

## 5. Drop Unused Places Functions

- [ ] 5.1 Delete `supabase/db/game_logic/functions/places/approve_pending_place.sql`
- [ ] 5.2 Delete `supabase/db/game_logic/functions/places/match_places.sql`

## 6. Drop Unused Utilities Functions

- [ ] 6.1 Delete `supabase/db/game_logic/functions/utilities/approve_pending_session.sql`
- [ ] 6.2 Delete `supabase/db/game_logic/functions/utilities/enrich_place_on_approval.sql`
- [ ] 6.3 Delete `supabase/db/game_logic/functions/utilities/geo_region_for.sql`
- [ ] 6.4 Delete `supabase/db/game_logic/functions/utilities/http_call_edge_function.sql`
- [ ] 6.5 Delete `supabase/db/game_logic/functions/utilities/update_embedding.sql`
- [ ] 6.6 Delete `supabase/db/game_logic/functions/utilities/update_place_embedding.sql`

## 7. Drop Unused Questions/Maintenance Functions

- [ ] 7.1 Delete `supabase/db/game_logic/functions/questions/update_question_effectiveness_batch.sql`
- [ ] 7.2 Delete `supabase/db/game_logic/functions/maintenance/maintenance_weekly.sql`

## 8. Update Functions Referencing Moved Tables

- [ ] 8.1 Update `get_embedding.sql`: reference `game_logic.embeddings` instead of `public.embeddings`
- [ ] 8.2 Update `generate_embedding.sql`: reference `game_logic.embeddings`
- [ ] 8.3 Update `filter_semantic_candidates.sql`: reference `game_logic.embeddings`
- [ ] 8.4 Update `get_geographic_questions.sql`: reference `game_logic.geographic_regions`
- [ ] 8.5 Update `filter_geographic_candidates.sql`: reference `game_logic.geographic_regions`
- [ ] 8.6 Update `handle_question.sql`: reference `game_logic.geographic_regions`
- [ ] 8.7 Update `record_game_answer.sql`: reference `game_logic.geographic_regions` if needed
- [ ] 8.8 Grep for any other references to `public.embeddings` or `public.geographic_regions` and update

## 9. Update Views

- [ ] 9.1 Update `global_stats.sql`: reference `game_logic.embeddings` for total_embeddings count
- [ ] 9.2 Verify `game_session_state.sql` doesn't reference moved tables directly

## 10. Update Tests

- [ ] 10.1 Update `test_schema_validation.sql`: remove `has_table('public', 'config')` test
- [ ] 10.2 Update `test_schema_validation.sql`: remove `has_table('game_logic', 'question_stats')` test
- [ ] 10.3 Update `test_schema_validation.sql`: remove `row_security_is_enabled('public', 'config')` test
- [ ] 10.4 Update `test_schema_validation.sql`: update embeddings/geographic_regions tests to game_logic schema
- [ ] 10.5 Update `test_schema_validation.sql`: update plan count
- [ ] 10.6 Update `test_rls_policies.sql`: remove `SELECT * FROM public.config` test
- [ ] 10.7 Update `test_rls_policies.sql`: update embeddings test for game_logic schema
- [ ] 10.8 Update `test_rls_policies.sql`: update geographic_regions test for game_logic schema
- [ ] 10.9 Update `test_rls_policies.sql`: update plan count
- [ ] 10.10 Update `test_algorithm_functions.sql`: remove `calculate_split_quality` tests (tests 16-18)
- [ ] 10.11 Update `test_algorithm_functions.sql`: remove `adjust_score` tests (tests 19-20)
- [ ] 10.12 Update `test_algorithm_functions.sql`: update plan count from 20 to 15

## 11. Rebuild and Verify

- [ ] 11.1 Run `bun run db:rebuild` to regenerate migration
- [ ] 11.2 Run `bun run test:db` to verify all tests pass
- [ ] 11.3 Run `bun run type-check` to verify TypeScript types still valid
- [ ] 11.4 Verify frontend still works (places, game flow)

## 12. Update Spec

- [ ] 12.1 Update `openspec/specs/database/spec.md` with modified requirements
