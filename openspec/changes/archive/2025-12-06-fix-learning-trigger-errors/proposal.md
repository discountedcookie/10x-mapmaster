# Change: Fix Learning Trigger and Error Handling

## Why

The learning system has two critical bugs discovered during testing:

1. The `enrich_place_on_session_complete_trigger` only fires on UPDATE, not INSERT - meaning sessions created with `was_correct = TRUE` never trigger learning
2. Multiple functions silently swallow errors with `RAISE WARNING` instead of failing properly with `RAISE EXCEPTION`

## What Changes

- Add INSERT to the `enrich_place_on_session_complete_trigger` definition
- Convert silent `RAISE WARNING` to `RAISE EXCEPTION` in trait extraction pipeline
- Ensure errors propagate so they can be debugged and fixed

## Impact

- Affected specs: database
- Affected code:
  - `supabase/db/schema/triggers.sql`
  - `supabase/db/game_logic/functions/utilities/enqueue_trait_extraction.sql`
  - `supabase/db/game_logic/functions/places/update_place_traits.sql`
