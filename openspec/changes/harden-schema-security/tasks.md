# Tasks: Harden Schema Security

## 1. Schema Infrastructure

- [ ] 1.1 Create `private` schema in `supabase/db/schema/01_extensions.sql`
- [ ] 1.2 Create `api` schema in `supabase/db/schema/01_extensions.sql`
- [ ] 1.3 Set up search_path defaults for new schemas
- [ ] 1.4 Grant USAGE on `api` to anon and authenticated roles
- [ ] 1.5 Revoke all on `private` schema from anon and authenticated

## 2. Reorganize Source Directory Structure

- [ ] 2.1 Rename `supabase/db/game_logic/` to `supabase/db/private/`
- [ ] 2.2 Move `supabase/db/public/tables/` to `supabase/db/private/tables/`
- [ ] 2.3 Move `supabase/db/public/functions/` to `supabase/db/private/functions/`
- [ ] 2.4 Create `supabase/db/api/` directory for views and RPCs
- [ ] 2.5 Move views from `supabase/db/public/views/` to `supabase/db/api/views/`
- [ ] 2.6 Create `supabase/db/api/functions/` for public-facing RPCs
- [ ] 2.7 Update `scripts/build-migration.ts` to reflect new directory structure

## 3. Update Table Definitions

- [ ] 3.1 Change `places` table schema from `public` to `private`
- [ ] 3.2 Change `traits` table schema from `public` to `private`
- [ ] 3.3 Change `place_traits` table schema from `public` to `private`
- [ ] 3.4 Change `game_sessions` table schema from `public` to `private`
- [ ] 3.5 Change `game_answers` table schema from `public` to `private`
- [ ] 3.6 Change `embeddings` table schema from `game_logic` to `private`
- [ ] 3.7 Change `config` table schema from `game_logic` to `private`
- [ ] 3.8 Change `geographic_regions` table schema from `game_logic` to `private`
- [ ] 3.9 Change `rate_limit_log` table schema from `game_logic` to `private`

## 4. Update RLS Policies

- [ ] 4.1 Remove anon/authenticated policies from `private.places` (keep service_role only)
- [ ] 4.2 Remove anon/authenticated policies from `private.traits` (keep service_role only)
- [ ] 4.3 Remove anon/authenticated policies from `private.place_traits` (keep service_role only)
- [ ] 4.4 Update `private.game_sessions` RLS to service_role only
- [ ] 4.5 Update `private.game_answers` RLS to service_role only
- [ ] 4.6 Verify `private.config` has service_role only policy
- [ ] 4.7 Verify `private.embeddings` has service_role only policy
- [ ] 4.8 Ensure rls_forced = TRUE on all security-sensitive tables

## 5. Update Internal Function References

- [ ] 5.1 Update all functions to use `private.` prefix instead of `public.`
- [ ] 5.2 Update all functions to use `private.` prefix instead of `game_logic.`
- [ ] 5.3 Rename `game_logic.get_config()` to `private.get_config()`
- [ ] 5.4 Rename `game_logic.check_rate_limit()` to `private.check_rate_limit()`
- [ ] 5.5 Update all trigger function references
- [ ] 5.6 Update all foreign key references across schema boundaries

## 6. Update API Views

- [ ] 6.1 Move `game_session_state` view to `api` schema
- [ ] 6.2 Update `game_session_state` to reference `private.game_sessions`
- [ ] 6.3 Move `places_with_geometry` view to `api` schema
- [ ] 6.4 Update `places_with_geometry` to reference `private.places`
- [ ] 6.5 Move `user_stats` view to `api` schema
- [ ] 6.6 Update `user_stats` to reference `private.game_sessions`
- [ ] 6.7 Move `global_stats` view to `api` schema
- [ ] 6.8 Update `global_stats` to reference private tables

## 7. Update API Functions (Public RPCs)

- [ ] 7.1 Move `start_game()` to `api` schema
- [ ] 7.2 Update `start_game()` to call private internal functions
- [ ] 7.3 Move `play_turn()` to `api` schema
- [ ] 7.4 Update `play_turn()` to call private internal functions
- [ ] 7.5 Move `submit_place()` to `api` schema
- [ ] 7.6 Update `submit_place()` to call private internal functions

## 8. Update API Permissions

- [ ] 8.1 Grant SELECT on `api.game_session_state` to authenticated
- [ ] 8.2 Grant SELECT on `api.places_with_geometry` to anon, authenticated
- [ ] 8.3 Grant SELECT on `api.user_stats` to authenticated
- [ ] 8.4 Grant SELECT on `api.global_stats` to authenticated
- [ ] 8.5 Grant EXECUTE on `api.start_game` to authenticated
- [ ] 8.6 Grant EXECUTE on `api.play_turn` to authenticated
- [ ] 8.7 Grant EXECUTE on `api.submit_place` to authenticated
- [ ] 8.8 Revoke all default privileges from public schema tables

## 9. Update Supabase Configuration

- [ ] 9.1 Update `supabase/config.toml` to expose only `api` schema
- [ ] 9.2 Remove `public` from exposed schemas list
- [ ] 9.3 Set `api` as the primary schema in extra_search_path

## 10. Update Frontend

- [ ] 10.1 Update `src/lib/supabase.ts` to use `api` schema
- [ ] 10.2 Verify all `.from()` calls work with new schema
- [ ] 10.3 Verify all `.rpc()` calls work with new schema

## 11. Update Database Tests

- [ ] 11.1 Update test setup to use new schema names
- [ ] 11.2 Update `test_places.sql` table references
- [ ] 11.3 Update `test_sessions.sql` table references
- [ ] 11.4 Update `test_game_flow.sql` table references
- [ ] 11.5 Update `test_algorithm.sql` function references
- [ ] 11.6 Add tests for schema isolation (verify clients can't access private)

## 12. Migration and Verification

- [ ] 12.1 Run `bun run db:rebuild` to generate new migration
- [ ] 12.2 Run `supabase db reset` to apply changes
- [ ] 12.3 Run `supabase test db` to verify all tests pass
- [ ] 12.4 Run frontend and verify game flow works
- [ ] 12.5 Verify Security Advisor shows no warnings
- [ ] 12.6 Document schema structure in `docs/architecture.md`
