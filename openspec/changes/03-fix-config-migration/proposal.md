# Change: Migrate Configuration to game_logic.config

## Why

Algorithm configuration is stored in `public.app_settings` with flat keys, but `docs/architecture/algorithm.md` specifies it should be in `game_logic.config` (server-only schema) with hierarchical keys like `confidence.top_prob_threshold`. Functions inconsistently query different tables.

## What Changes

- **Schema**: Migrate algorithm config from `app_settings` to `game_logic.config`
- **Key naming**: Change flat keys to hierarchical (`top_prob_threshold` -> `confidence.top_prob_threshold`)
- **Standardize access**: Update all game logic functions to read from `game_logic.config`
- **Separation**: Keep only client-visible config in `public.config`

## Impact

- Affected specs: database
- Affected code: `supabase/db/game_logic/`, `supabase/seeds/00_static_data.sql`
- Improves security by keeping algorithm parameters server-only
