# Change: Add Game Sessions

## Why

Store game session state, metadata, and lifecycle fields required by gameplay.

## What Changes

- Create game_sessions table with status enum, pending_review, was_correct, next_turn JSONB, embedding_id, place_id
- Add constraints, indexes, and comments

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/game_sessions.sql
