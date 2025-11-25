# Design: Edge Functions

## Execution Plan

1. **Shared utilities** – Type definitions, provider selection helpers, error mappers.
2. **Embedding function** – Generate 384d vectors with provider toggle + deterministic mocks.
3. **LLM function** – Single entry point for question generation and trait extraction prompts.
4. **Place enrichment** – Wrapper around Nominatim + enrichment logic.
5. **Search place** – Query Nominatim and expose safe subset to frontend.

## Dependencies

- Requires database foundation schema for storing embeddings/traits.
- Algorithm/game-core work depends on these functions being stable.

## Agents

- **Primary:** @supabase-expert (Edge functions live near database boundary)
- **Support:** build agent for CI wiring/mocks

## Risks & Mitigations

| Risk              | Mitigation                                                              |
| ----------------- | ----------------------------------------------------------------------- |
| Provider variance | Keep abstraction in `_shared/provider.ts`, document supported providers |
| Secrets leakage   | Only read from environment variables, never log secrets                 |
| Slow tests        | Provide lightweight mocks for Playwright + Vitest                       |
