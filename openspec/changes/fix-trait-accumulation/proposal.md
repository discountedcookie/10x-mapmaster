# Change: Fix trait accumulation with sequential processing

## Why

Two issues cause learned knowledge to be lost:

1. **Trait replacement**: `update_place_traits` deletes all traits before inserting new ones, so the LLM must perfectly reproduce existing traits or they're lost

2. **Concurrent execution**: Multiple sessions approved for the same place trigger parallel extractions that race against each other - only the last one survives

## What Changes

- Remove the `DELETE FROM place_traits` statement - accumulate instead of replace
- Add semantic deduplication to prevent storing equivalent traits
- Add per-place sequential processing via pgmq to ensure each extraction sees previous results

## Impact

- Affected specs: database
- Affected code:
  - `supabase/db/game_logic/functions/places/update_place_traits.sql`
  - `supabase/db/game_logic/functions/utilities/enqueue_trait_extraction.sql`
  - `supabase/functions/process-trait-extraction/`
- **BREAKING**: None - behavior fix, not API change
