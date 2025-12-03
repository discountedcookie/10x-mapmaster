## 1. Create Shared Utilities

- [ ] 1.1 Create `supabase/functions/utils/retry.ts` with exponential backoff
- [ ] 1.2 Create `supabase/functions/utils/timeout.ts` with AbortController wrapper
- [ ] 1.3 Create `supabase/functions/utils/errors.ts` with structured error types
- [ ] 1.4 Export utilities from `supabase/functions/utils/index.ts`

## 2. Harden generate-embedding

- [ ] 2.1 Wrap HuggingFace API call with retry logic
- [ ] 2.2 Add 30s timeout to fetch request
- [ ] 2.3 Return structured errors for failures
- [ ] 2.4 Add early validation for empty HF_TOKEN

## 3. Harden call-llm

- [ ] 3.1 Wrap OpenRouter API call with retry logic
- [ ] 3.2 Add 60s timeout for LLM requests (longer due to generation)
- [ ] 3.3 Return structured errors for failures
- [ ] 3.4 Handle rate limiting (429) with longer backoff

## 4. Harden process-trait-extraction

- [ ] 4.1 Apply retry/timeout to internal function calls
- [ ] 4.2 Return structured errors for failures
- [ ] 4.3 Handle partial failures gracefully

## 5. Verify

- [ ] 5.1 Test with simulated network failures
- [ ] 5.2 Test timeout behavior
- [ ] 5.3 Verify error response format matches spec
