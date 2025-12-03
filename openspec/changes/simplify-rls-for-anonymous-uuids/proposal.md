# Change: Simplify RLS for Anonymous UUID Users

## Why

The current documentation and some RLS comments imply support for `user_id IS NULL` patterns, but in practice all users (including anonymous ones) have a UUID via Supabase anon auth. This mismatch makes RLS behavior harder to reason about and the docs misleading.

## What Changes

- Align RLS documentation and specs with the actual model: all users have `auth.uid()`, and `user_id` should always be set for game sessions.
- Simplify or remove any RLS or view logic that assumes `user_id IS NULL` as a supported access path.
- Tighten RLS tests to assert the UUID-based anonymous behavior explicitly.

## Impact

- Affected specs: `database` (RLS policies and auth model), potentially `game-core` (session ownership assumptions).
- Affected code: `supabase/db/public/tables/game_sessions.sql`, `supabase/db/public/tables/game_answers.sql`, `supabase/db/public/views/game_session_state.sql`, and any RLS-related docs.
- RLS will be easier to understand and maintain, and documentation will match actual production behavior.
