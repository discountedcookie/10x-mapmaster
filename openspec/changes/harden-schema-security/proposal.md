# Change: Harden Database Schema Security

## Why

The current database structure exposes ALL tables in the `public` schema via PostgREST, relying solely on RLS for protection. This violates the principle of least privilege - tables like `game_sessions`, `game_answers`, and `traits` are directly accessible when the frontend only needs views and RPCs. Following Supabase's official "Hardening the Data API" guidance (December 2025), we should move tables to a `private` schema and expose only a controlled `api` schema.

## What Changes

### Schema Structure

- **Rename** `game_logic` schema to `private` (Supabase-recommended name)
- **Move** all tables from `public` to `private` schema
- **Create** `api` schema containing only views and RPCs
- **Remove** `public` from exposed schemas in Supabase config
- **Tighten** GRANTs to minimum required permissions

### Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  FRONTEND (anon/authenticated)                                  │
│  Can ONLY access: api.* schema via PostgREST                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  api SCHEMA (EXPOSED)                                           │
│  Views: game_session_state, places_with_geometry, user_stats,   │
│         global_stats                                            │
│  RPCs: start_game(), play_turn(), submit_place()                │
│  Permissions: SELECT on views, EXECUTE on functions             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  private SCHEMA (NOT EXPOSED)                                   │
│  Tables: places, traits, place_traits, embeddings, config,      │
│          geographic_regions, game_sessions, game_answers,       │
│          rate_limit_log                                         │
│  Functions: All algorithm and utility functions                 │
│  Permissions: No client access, only via SECURITY DEFINER       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  public SCHEMA (NOT EXPOSED)                                    │
│  Reserved for: Extensions, types, enums                         │
│  No tables, no direct client access                             │
└─────────────────────────────────────────────────────────────────┘
```

### Permission Model

| Object | anon | authenticated | service_role |
|--------|------|---------------|--------------|
| api.game_session_state | - | SELECT | ALL |
| api.places_with_geometry | SELECT | SELECT | ALL |
| api.user_stats | - | SELECT | ALL |
| api.global_stats | - | SELECT | ALL |
| api.start_game() | - | EXECUTE | ALL |
| api.play_turn() | - | EXECUTE | ALL |
| api.submit_place() | - | EXECUTE | ALL |
| private.* tables | - | - | ALL |

## Impact

- **Affected specs**: `database` (major changes to schemas and RLS requirements)
- **Affected code**:
  - `supabase/db/schema/` - Schema definitions
  - `supabase/db/public/` → `supabase/db/private/` - Rename directory
  - `supabase/db/game_logic/` → merge into `supabase/db/private/`
  - All SQL files with schema references
  - `src/lib/supabase.ts` - Update client schema config
  - `supabase/config.toml` - Update exposed schemas

## Security Improvements

1. **Defense in depth**: Tables are not exposed even if RLS is misconfigured
2. **Explicit API surface**: Frontend can only call what's in `api` schema
3. **No accidental exposure**: New tables in `private` are hidden by default
4. **Follows Supabase best practices**: Uses their recommended `private` naming

## Migration Strategy

This is a **breaking schema change** requiring a fresh migration:
1. Create new `private` and `api` schemas
2. Move all tables to `private`
3. Create views/functions in `api`
4. Update all internal function references
5. Run `db:rebuild` to regenerate migration
