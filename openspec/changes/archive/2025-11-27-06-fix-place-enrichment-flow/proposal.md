# Change: Fix Place Enrichment Flow

## Why

The current architecture has the `place-enrichment` edge function doing too much work:

- Calling Nominatim
- Extracting traits (rule-based + LLM)
- Returning combined results

This violates database-first architecture. The database should orchestrate the flow and only delegate LLM calls to edge functions.

## What Changes

- **REMOVE** `place-enrichment` edge function
- **REMOVE** `_shared/enrichment.ts` and `_shared/traits.ts`
- **MODIFY** `submit_place.sql` to:
  1. Call Nominatim directly via `http` extension
  2. Call `call-llm` edge function with Nominatim data for trait extraction
  3. Store place + traits
- **MODIFY** `call-llm` edge function to handle `trait_extraction` request type
- **REMOVE** `LLM_EXTRACTION_ENABLED` env var - use `game_logic.config` instead

## Impact

- Affected specs: `edge-functions`, `database`
- Affected code:
  - `supabase/functions/place-enrichment/` (DELETE)
  - `supabase/functions/_shared/enrichment.ts` (DELETE)
  - `supabase/functions/_shared/traits.ts` (DELETE)
  - `supabase/db/public/functions/submit_place.sql` (MODIFY)
  - `supabase/functions/call-llm/index.ts` (MODIFY)
  - `scripts/generate-test-seed.ts` (MODIFY - remove enrichment imports)
