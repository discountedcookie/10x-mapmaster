# Change: Add Rate Limiting

## Why

Enforce per-user rate limits for RPC calls to prevent abuse.

## What Changes

- Add rate_limit_log table and RLS/permissions
- Implement check_rate_limit function using config defaults
- Document limits and cleanup mechanism

## Impact

- Affected specs: operations
- Affected code: supabase/db/game_logic/tables/rate_limit_log.sql, functions/utilities/check_rate_limit.sql, config
