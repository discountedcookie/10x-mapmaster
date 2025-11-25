# Change: Database Foundation

## Why

Establish the PostgreSQL foundation that powers every other capability. The current schema is incomplete, mixes public and game logic concerns, and lacks the rate limiting and statistics views defined in the spec. We need a clean, source-based schema that RLS can protect and downstream code can rely on.

## Scope

- Core tables (places, traits, embeddings, geographic_regions, game_sessions, game_answers, config tables, rate_limit_log)
- Schema organization (public vs game_logic)
- Row Level Security policies and SECURITY DEFINER helpers
- Stats views (user_stats, global_stats)
- Error response composite type
- Source-based migration workflow (supabase/db/schema/\*)

## Impact

- Enables edge functions and algorithms to persist and query consistent data
- Unblocks frontend contract work (typed RPC responses)
- Provides database-enforced security boundaries from day one

## Success Criteria

- `supabase/db/schema/` defines all tables, indexes, triggers, views listed in spec
- `supabase/tests/test_game_basics.sql` and `test_settings_control_behavior.sql` cover schema invariants
- `bun run db:rebuild` recreates schema without manual edits
- RLS policies keep anonymous/registered users isolated
- Config reads split between `public.config` and `game_logic.config`
