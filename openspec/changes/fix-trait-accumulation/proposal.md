# Change: Fix trait accumulation with knowledge curation

## Why

Two issues cause learned knowledge to be lost:

1. **Trait replacement**: `update_place_traits` deletes all traits before inserting new ones, so the LLM must perfectly reproduce existing traits or they're lost

2. **Concurrent execution**: Multiple sessions approved for the same place trigger parallel extractions that race against each other - only the last one survives

## What Changes

### 1. Database: Remove trait deletion

- Remove `DELETE FROM place_traits` statement
- Traits accumulate instead of being replaced
- Existing `ON CONFLICT DO NOTHING` prevents exact duplicates

### 2. Prompt: Reframe as knowledge curation

- LLM curates the knowledge base (keep/add/remove/consolidate)
- Output includes brief reasoning about changes made
- Traits must be naturally readable (displayed in UI as "What I know about this place")
- Increase max traits from 20 to 30

### 3. Nominatim formatting

- Format extratags as simple `key: value` lines instead of raw JSON
- Clearer input for LLM, better trait extraction

### 4. Queue processing

- Edge function already processes one message at a time
- Verify sequential processing works correctly

## Deferred to Phase 2

- Semantic deduplication (embedding similarity)
- Trait categorization/grouping
- Per-place parallel processing

## Impact

- Affected specs: database
- Affected code:
  - `supabase/db/game_logic/functions/places/update_place_traits.sql`
  - `supabase/db/game_logic/data/config.sql`
- **BREAKING**: None - behavior improvement, not API change
