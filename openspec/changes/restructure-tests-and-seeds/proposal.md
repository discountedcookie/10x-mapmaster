# Proposal: Restructure Tests and Seeds

## Problem

1. **Seeds mix production and dev data** - runtime keys, test users, and required config are in the same files
2. **Tests are organized by type, not domain** - `test_tables_*.sql` instead of `test_places.sql`
3. **70% of tests are structural waste** - testing "table exists" instead of behavior
4. **Frontend tests mock everything** - testing mocks, not real logic
5. **Geographic regions and config are seeds but should be schema** - they're required for the app to function

## Solution

### 1. Move Required Data to Schema

Move config and geographic regions from seeds to `supabase/db/game_logic/data/`:

- `config.sql` - game configuration (no runtime.\* keys)
- `geographic_regions.sql` - generated from Natural Earth

These become part of the migration, not optional seed data.

### 2. Simplify Seeds to Dev-Only

Consolidate seeds to just dev/test data:

- `00_dev_runtime.sql` - runtime.\* keys for local Docker networking
- `01_dev_users.sql` - test users for local development
- `02_dev_data.sql` - pre-computed embeddings and test places

### 3. Reorganize DB Tests by Domain

Delete structural tests, consolidate by domain:

- `test_game_flow.sql` - start_game, play_turn, game state machine
- `test_places.sql` - places RLS, submit_place
- `test_sessions.sql` - sessions RLS, answers RLS
- `test_algorithm.sql` - scoring functions (keep existing)

Delete:

- `test_schema.sql`
- `test_tables_*.sql` (all 8 files)
- `test_views_*.sql` (all 3 files)

### 4. Trim Frontend Tests

Delete mock-based tests, keep only pure logic:

- Keep: validation, sorting, state machine guards
- Delete: "should call API", "should handle API error"

### 5. Update Generation Script

Modify `scripts/generate-geographic-regions.ts` to output to `supabase/db/game_logic/data/geographic_regions.sql`.

## Requirements

### REQ-1: Schema Data Files

Data required for app function MUST be in `supabase/db/game_logic/data/` and included in migrations.

**Scenario:** Fresh production deployment

- Given: Only migrations are run (no seeds)
- When: User starts a game
- Then: Config values exist and geographic regions are available

### REQ-2: Dev-Only Seeds

Seeds MUST contain only development/test data that is NOT required for production.

**Scenario:** Production deployment

- Given: Seeds are not run
- When: App starts
- Then: App functions correctly (config and regions from migration)

### REQ-3: Domain-Organized Tests

Database tests MUST be organized by domain (places, sessions, game_flow) not by object type (tables, views).

**Scenario:** Developer changes places logic

- Given: Places-related change
- When: Running tests
- Then: Single `test_places.sql` file contains all places behavior tests

### REQ-4: Behavioral Tests Only

Tests MUST verify behavior, not structure. "Table exists" tests MUST be removed.

**Scenario:** Schema refactoring

- Given: Table moved to different schema
- When: Tests run
- Then: Tests pass if behavior unchanged (no structural test failures)

## Impact

- **Test count:** 158 → ~50 (focused, valuable)
- **Test files:** 16 → 5
- **Seed files:** 3 (mixed) → 3 (dev-only)
- **New schema files:** 2 (config, geographic_regions)

## Migration Path

1. Create `supabase/db/game_logic/data/` directory
2. Extract config from seeds → `data/config.sql`
3. Move geographic regions → `data/geographic_regions.sql`
4. Update `scripts/generate-geographic-regions.ts` output path
5. Consolidate seeds to dev-only files
6. Consolidate DB tests by domain
7. Delete structural tests
8. Trim frontend tests
9. Run `db:rebuild` and verify all tests pass
