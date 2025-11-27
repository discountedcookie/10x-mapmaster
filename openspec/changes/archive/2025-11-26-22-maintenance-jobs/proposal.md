# Change: Add Maintenance Jobs

## Why

Automate cleanup tasks (rate limit logs, abandoned sessions) via pg_cron for operational hygiene.

## What Changes

- Define pg_cron jobs for rate_limit_log cleanup and abandoned session deletion
- Implement supporting functions

## Impact

- Affected specs: operations
- Affected code: supabase/db/schema/cron entries, maintenance functions
