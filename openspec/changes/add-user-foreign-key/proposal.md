# Change: Add User Foreign Key Constraint

## Why

The `game_sessions.user_id` column references `auth.users.id` but has no foreign key constraint. This means:

- Orphaned sessions can exist if a user is deleted
- No referential integrity at the database level
- Relies entirely on application logic for consistency

Database constraints are more reliable than application logic.

## What Changes

- Add FK constraint from `game_sessions.user_id` to `auth.users.id`
- Use `ON DELETE CASCADE` to clean up sessions when users are deleted
- Add migration to handle any existing orphaned records

## Impact

- Affected specs: `database` (Schema integrity)
- Affected code:
  - `supabase/db/public/tables/game_sessions.sql`
