# Change: Add play_turn RPC

## Why

Process player answers, update candidates, decide next action, and return the updated session reference.

## What Changes

- Implement play_turn RPC with recording of answers and candidate update
- Apply confidence/selection logic to set next_turn
- Return session_id with standardized error handling

## Impact

- Affected specs: game-core
- Affected code: supabase/db/public/functions/play_turn.sql and dependencies
