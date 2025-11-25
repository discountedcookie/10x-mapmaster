# Change: Edge Functions

## Why

Database logic depends on deterministic LLM, embedding, and Nominatim integrations. The current edge functions are incomplete, environment-specific, and undocumented. We need consistent, provider-agnostic Deno functions with strong input/output contracts.

## Scope

- `generate-embedding`, `call-llm`, and `search-place` functions
- Shared enrichment utilities and type definitions
- Provider toggles for local (Ollama) vs production (Supabase hosted models)
- Error translation for database consumption

## Impact

- Allows database functions to request embeddings and LLM output without leaking credentials
- Enables place enrichment pipeline and learning loop
- Provides deterministic mocks for tests and e2e runs

## Success Criteria

- Each edge function documented in `supabase/functions/*/README` with input/output
- Provider selection driven by environment variables
- Error codes normalized for `error_response`
- Tests/mocks available for Playwright suite
