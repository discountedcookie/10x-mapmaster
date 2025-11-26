# Tasks: Edge Functions

## Phase 1 – Shared Infrastructure

- [x] 1.1 Define provider selection + typings (`supabase/functions/_shared/*`) (openspec/specs/edge-functions/spec.md#provider-agnostic-architecture)
- [x] 1.2 Implement unified error mapper → `error_response` (openspec/specs/database/spec.md#error-response-structure)

## Phase 2 – Embedding Service

- [x] 2.1 Implement `generate-embedding` function with provider toggle (openspec/specs/edge-functions/spec.md#generate-embedding-function)
- [ ] 2.2 Add deterministic mock + tests for embeddings (spec/ui.md#chat-interface for dev flows)

## Phase 3 – LLM Gateway

- [x] 3.1 Implement `call-llm` function with context builders (openspec/specs/edge-functions/spec.md#call-llm-function)
- [ ] 3.2 Provide prompt templates + language support (spec/gameplay.md#question-selection)

## Phase 4 – Place Services

- [x] 4.1 Implement `place-enrichment` edge function (openspec/specs/edge-functions/spec.md#fetch-place-function)
- [x] 4.2 Implement `search-place` function for frontend place search (spec/gameplay.md#place-submission)
- [x] 4.3 Add shared enrichment utilities + tests (spec/operations.md#testing-strategy)

## Phase 5 – Tooling

- [x] 5.1 Document local vs production setup in `supabase/functions/README.md`
- [ ] 5.2 Update CI to lint/ts-check edge functions (spec/operations.md#ci/cd-pipeline)

## Notes

### Completed ✅

- All core edge functions implemented with consistent patterns
- Unified error handling and logging across all functions
- Comprehensive documentation with examples and setup instructions
- Shared utilities for place enrichment and trait extraction
- Proper TypeScript types and validation

### Remaining ⏳

- Task 2.2: Mock embeddings for development/testing
- Task 3.2: Prompt templates and multi-language support
- Task 5.2: CI/CD pipeline updates for TypeScript checking

### Issues Found & Fixed

- Fixed inconsistent Deno.serve patterns across functions
- Removed unnecessary authentication from search-place (other functions are public)
- Standardized error response format and logging
- Added comprehensive environment variable documentation
- Improved input validation and error messages
