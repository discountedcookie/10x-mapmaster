## 1. Remove Dead Code

- [x] 1.1 Delete `supabase/functions/place-enrichment/` directory
- [x] 1.2 Delete `supabase/functions/_shared/enrichment.ts`
- [x] 1.3 Delete `supabase/functions/_shared/traits.ts`
- [x] 1.4 Update `scripts/generate-test-seed.ts` to remove enrichment imports

## 2. Database-First Architecture

- [x] 2.1 Create `game_logic.fetch_nominatim_place(osm_id)` - calls Nominatim via http extension
- [x] 2.2 Create `game_logic.extract_traits_from_nominatim(nominatim_data)` - LLM + rule-based trait extraction
- [x] 2.3 Create `game_logic.create_place_with_traits(osm_id, nominatim_data, traits)` - creates place, traits, embedding
- [x] 2.4 Rewrite `submit_place.sql` as thin orchestration calling the 3 helper functions

## 3. LLM Configuration

- [x] 3.1 Add `p_config_prefix` parameter to `call_llm_api` for per-use-case model settings
- [x] 3.2 Add `llm.extraction.*` config keys for trait extraction model settings
- [x] 3.3 Update `extract_traits_from_nominatim` to use `llm.extraction` config prefix

## 4. Seed Data Generation

- [x] 4.1 Rewrite `generate-test-seed.ts` to use DB functions (not edge functions)
- [x] 4.2 Fix geometry column to accept Point/Polygon/MultiPolygon from Nominatim
- [x] 4.3 Fix geometry serialization (WKT via ST_AsText/ST_GeomFromText)
- [x] 4.4 Trim places.json to 20 reliable places

## 5. Testing

- [x] 5.1 Run `db:rebuild` and verify migration succeeds
- [x] 5.2 Run `supabase test db` - all 78 tests pass
- [x] 5.3 Play full game via SQL - win scenario verified
