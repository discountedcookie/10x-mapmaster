## 1. LLM Extraction Function

- [x] 1.1 Create `extractTraitsViaLLM()` function in `_shared/traits.ts`
- [x] 1.2 Build prompt that includes Nominatim fields (class, type, extratags, addresstags)
- [x] 1.3 Parse LLM response to create trait objects with clause/category
- [x] 1.4 Call `call-llm` edge function with extraction mode

## 2. Configuration

- [x] 2.1 Add `llm.extraction.prompt` to config with trait extraction prompt template
- [x] 2.2 Add `llm.extraction.model`, `llm.extraction.temperature` config values
- [x] 2.3 Add `llm.extraction.enabled` flag for gradual rollout

## 3. Integration

- [x] 3.1 Update `place-enrichment` to call `extractTraitsViaLLM()` when enabled
- [x] 3.2 Merge LLM-extracted traits with rule-based traits (deduplication)
- [x] 3.3 Add fallback to rule-based extraction on LLM failure

## 4. Testing

- [ ] 4.1 Unit test for `extractTraitsViaLLM()` with mocked LLM response
- [ ] 4.2 Integration test for place-enrichment with LLM extraction
- [ ] 4.3 Compare trait quality: LLM vs rule-based for same places
