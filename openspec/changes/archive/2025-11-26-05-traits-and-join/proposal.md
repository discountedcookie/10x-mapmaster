# Change: Add Traits and Join

## Why

Define canonical traits and their association to places to support semantic questioning and learning.

## What Changes

- Create traits table (id, clause, embedding_id optional)
- Create place_traits join table linking places to traits
- Add indexes and RLS posture for read-open traits

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/traits.sql, place_traits.sql
