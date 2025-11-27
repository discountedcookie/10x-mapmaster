# Change: Implement LLM-Based Trait Extraction

## Why

Per `docs/architecture/algorithm.md`: "Traits are extracted from real Nominatim data by LLM, not invented or hardcoded". Currently, `supabase/functions/_shared/traits.ts` uses hardcoded rules (height buckets, class/type fields, extratags patterns). This limits semantic richness.

## What Changes

- **LLM extraction**: Call `call-llm` to extract semantic trait descriptions from Nominatim data
- **Prompt template**: Add `llm.extraction.prompt` config for trait extraction
- **Fallback**: Keep current rule-based extraction as fallback for reliability
- **Integration**: Update `place-enrichment` edge function to use LLM extraction

## Impact

- Affected specs: edge-functions
- Affected code: `supabase/functions/place-enrichment/`, `supabase/functions/_shared/traits.ts`
- Produces richer, more semantically meaningful traits
