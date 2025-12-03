# Change: Harden Edge Functions

## Why

The edge functions call external APIs (HuggingFace for embeddings, OpenRouter for LLM) without resilience patterns:

- No retry logic for transient failures
- No request timeouts (could hang indefinitely)
- No circuit breaker for repeated failures

External APIs fail. Production code must handle this gracefully.

## What Changes

- Add retry logic with exponential backoff for external API calls
- Add request timeouts (30s default, configurable)
- Add structured error responses for different failure modes
- Consider adding a simple circuit breaker pattern

## Impact

- Affected specs: `edge-functions`
- Affected code:
  - `supabase/functions/generate-embedding/index.ts`
  - `supabase/functions/call-llm/index.ts`
  - `supabase/functions/process-trait-extraction/index.ts`
