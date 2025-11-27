# Change: Add start_game RPC

## Why

Provide the public entrypoint to start a game session, embed the description, seed candidates, and set the first turn.

## What Changes

- Implement start_game RPC with validation and standardized error handling
- Integrate embedding generation and initial candidate selection
- Set next_turn JSON and return session_id

## Impact

- Affected specs: game-core
- Affected code: supabase/db/public/functions/start_game.sql and dependencies
