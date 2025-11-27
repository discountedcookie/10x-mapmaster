# Change: Add Game Answers

## Why

Persist answers with enforced one-of foreign key semantics and prepare for ownership isolation.

## What Changes

- Create game_answers table with trait_id/geographic_region_id/place_id mutually exclusive
- Add constraints, indexes, FKs, and comments

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/game_answers.sql
