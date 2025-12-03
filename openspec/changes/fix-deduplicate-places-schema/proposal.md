# Change: Fix deduplicate_places Schema Mismatch

## Why

The `game_logic.deduplicate_places()` function references columns that do not exist in the `places` table:

- `nominatim_place_id` (should be `osm_id`)
- `descriptors` (does not exist - place traits are in separate `place_traits` table)

This function will crash at runtime if called. It's used by scheduled maintenance, so this is a latent production bug.

## What Changes

- Remove `descriptors` column references (trait merging is out of scope for deduplication)
- Replace `nominatim_place_id` with `osm_id` to match actual schema
- Simplify function to only merge `times_encountered` during deduplication
- Add pgTAP tests for the function

## Impact

- Affected specs: `database` (maintenance functions)
- Affected code:
  - `supabase/db/game_logic/functions/places/deduplicate_places.sql`
  - `supabase/tests/` (new test file)
