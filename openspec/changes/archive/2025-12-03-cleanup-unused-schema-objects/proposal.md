# Change: Remove unused database schema objects

## Why

Database schema has accumulated dead code: 3 unused tables, 14 unused functions, and 2 tables incorrectly placed in `public` schema that should be in `game_logic`. This adds maintenance burden and confuses the architecture.

## What Changes

### Tables to DROP

- `public.app_settings` - Unused legacy (seed confirms "no longer used")
- `public.config` - Unused, all config uses `game_logic.config`
- `game_logic.question_stats` - Never populated, associated function never called

### Tables to MOVE to `game_logic`

- `public.embeddings` - Internal only, already has REVOKE for all roles
- `public.geographic_regions` - Internal only, never accessed by frontend

### Functions to DROP (14 total)

- `game_logic.update_question_effectiveness_batch` - Never called
- `game_logic.adjust_score` - Never called
- `game_logic.calculate_split_quality` - Never called
- `game_logic.filter_candidates_by_geography` - Never called (uses different function)
- `game_logic.calculate_trait_match_strength` - Never called
- `game_logic.approve_pending_place` - Never called
- `game_logic.approve_pending_session` - Never called
- `game_logic.enrich_place_on_approval` - Never called
- `game_logic.match_places` - Never called
- `game_logic.geo_region_for` - Never called (replaced by geographic_regions table)
- `game_logic.http_call_edge_function` - Never called
- `game_logic.update_embedding` - Never called
- `game_logic.update_place_embedding` - Never called
- `game_logic.maintenance_weekly` - Never called (only maintenance_cleanup is scheduled)

### Tests to UPDATE

- `test_schema_validation.sql` - Remove tests for dropped tables, update counts
- `test_rls_policies.sql` - Remove public.config test, update moved table tests
- `test_algorithm_functions.sql` - Remove tests for dropped functions

### Spec Updates

- Update database spec: remove `public.config` requirement, clarify schema placement

## Impact

- Affected specs: `database`
- Affected code: `supabase/db/`, `supabase/tests/`
- **Net reduction**: ~17 dead objects removed
- **No breaking changes**: All removed objects are unused
