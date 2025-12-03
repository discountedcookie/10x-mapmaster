# Change: Add Async Trait Extraction with pgmq

## Why

When a game ends (correct guess or place submission), the `update_place_traits` function blocks the transaction with multiple HTTP calls (Nominatim, LLM, embeddings). This causes REST API timeouts (8s default) when LLM providers are slow or rate-limited, leaving games in corrupted states.

## What Changes

- Enable `pgmq` extension for message queue functionality
- Create `trait_extraction` queue for async job processing
- Modify `enrich_place_on_session_complete` trigger to:
  1. Enqueue job via `pgmq.send()`
  2. Fire pg_net to edge function for immediate processing
- Add `process_trait_extraction_queue` edge function endpoint
- Add pg_cron job as backup processor for failed/orphaned messages

## Architecture

```
TRIGGER fires (game won)
    │
    ├─► pgmq.send('trait_extraction', {place_id})   ← Queue for durability
    │
    └─► pg_net.http_post('/functions/v1/process-trait-extraction')  ← Fire-and-forget
    │
    ▼
TRANSACTION COMMITS IMMEDIATELY (user sees success)

[Separate request processes via existing edge functions]
    └─► process-trait-extraction edge function
          └─► Calls update_place_traits RPC (uses existing edge functions internally)

[pg_cron backup - every 60s]
    └─► Processes any orphaned messages in queue
```

## What Stays the Same

- `update_place_traits` function (unchanged)
- `call-llm` edge function (unchanged)
- `generate-embedding` edge function (unchanged)
- All existing HTTP call patterns within `update_place_traits`

## Impact

- Affected specs: database (new extension, queue, trigger changes)
- Affected code:
  - `supabase/db/schema/01_extensions.sql` - add pgmq
  - `supabase/db/game_logic/functions/utilities/enrich_place_on_session_complete.sql` - async pattern
  - New: `supabase/functions/process-trait-extraction/index.ts`
  - New: `supabase/db/schema/05_queues.sql` - queue setup
  - New: `supabase/db/schema/06_cron_jobs.sql` - backup processor

## Non-Goals

- Moving edge functions to database (explicitly deferred)
- Changing `update_place_traits` internals
- Adding UI for queue monitoring
