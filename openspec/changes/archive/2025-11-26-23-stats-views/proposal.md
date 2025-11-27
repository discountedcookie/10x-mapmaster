# Change: Add Stats Views

## Why

Expose aggregated user and global gameplay statistics via read-only views with correct permissions.

## What Changes

- Create user_stats and global_stats views with required columns
- Set appropriate access controls

## Impact

- Affected specs: database
- Affected code: supabase/db/public/views/user_stats.sql, global_stats.sql
