# Change: Add Session RLS

## Why

Enforce ownership and isolation for sessions and answers consistent with auth posture (anonymous vs registered).

## What Changes

- Enable and force RLS on game_sessions and game_answers
- Add policies for select/insert/update per owner and service_role

## Impact

- Affected specs: database
- Affected code: RLS policy files for game_sessions and game_answers
