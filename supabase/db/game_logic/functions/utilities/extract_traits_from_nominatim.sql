-- Function: extract_traits_from_nominatim
-- Category: utilities
-- Purpose: Extract traits from Nominatim data using LLM + rule-based extraction
CREATE OR REPLACE FUNCTION "game_logic"."extract_traits_from_nominatim" ("p_nominatim_data" JSONB) 
returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_llm_enabled BOOLEAN;
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits JSONB;
  v_name TEXT;
  v_display_name TEXT;
  v_extratags JSONB;
  v_address JSONB;
BEGIN
  -- Extract fields for prompt
  v_name := COALESCE(
    p_nominatim_data->'namedetails'->>'name:en',
    p_nominatim_data->>'name',
    p_nominatim_data->>'display_name'
  );
  v_display_name := p_nominatim_data->>'display_name';
  v_extratags := COALESCE(p_nominatim_data->'extratags', '{}'::jsonb);
  v_address := COALESCE(p_nominatim_data->'address', '{}'::jsonb);

  -- Check if LLM trait extraction is enabled
  v_llm_enabled := COALESCE(
    (game_logic.get_config('llm.extraction.enabled')#>>'{}')::BOOLEAN,
    TRUE
  );

  v_traits := '[]'::jsonb;
  
  -- ============================================================================
  -- LLM TRAIT EXTRACTION (if enabled)
  -- ============================================================================
  IF v_llm_enabled THEN
    v_llm_prompt := format(
      E'You are extracting traits for a geographic guessing game. Given place data, extract 5-8 distinctive traits that would help players guess this location.

Place: %s
Full address: %s
Category: %s/%s
Country: %s
Additional info: %s

Extract traits covering:
1. What it IS (temple, tower, mountain, waterfall, etc.)
2. Religious/cultural significance (Buddhist, Hindu, Christian, Islamic, ancient, etc.)
3. Historical period (ancient, medieval, 19th century, modern, etc.)
4. Physical features (tall, stone, iron, carved, etc.)
5. Famous for (UNESCO site, wonder of world, pilgrimage, etc.)
6. Geographic context (coastal, mountain, desert, jungle, etc.)

Return a JSON array with 5-8 traits:
[{"id": "category:value", "clause": "Human readable description"}]

Example for Angkor Wat:
[
  {"id": "type:temple", "clause": "Ancient temple complex"},
  {"id": "religion:buddhist", "clause": "Buddhist religious site"},
  {"id": "religion:hindu", "clause": "Originally Hindu temple"},
  {"id": "era:medieval", "clause": "Built in 12th century"},
  {"id": "feature:stone", "clause": "Made of sandstone"},
  {"id": "status:unesco", "clause": "UNESCO World Heritage Site"},
  {"id": "fame:wonder", "clause": "Largest religious monument in world"}
]

Return ONLY the JSON array.',
      v_name,
      v_display_name,
      p_nominatim_data->>'class',
      p_nominatim_data->>'type',
      v_address->>'country',
      v_extratags::text
    );

    RAISE NOTICE 'Calling LLM for trait extraction';

    -- Use llm.extraction config prefix for extraction-specific model settings
    -- Note: Don't pass 'json' format - gemma returns cleaner JSON arrays without it
    v_llm_response := game_logic.call_llm_api(v_llm_prompt, NULL, 'llm.extraction');
    
    -- Strip markdown code fences if present (```json ... ```)
    v_llm_response := regexp_replace(v_llm_response, '^```json\s*', '', 'i');
    v_llm_response := regexp_replace(v_llm_response, '\s*```$', '', 'i');
    v_llm_response := trim(v_llm_response);
    
    v_traits := v_llm_response::jsonb;
  END IF;

  -- ============================================================================
  -- RULE-BASED TRAITS (always, supplements LLM)
  -- ============================================================================
  -- Add class as trait
  IF p_nominatim_data->>'class' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'class:' || lower(p_nominatim_data->>'class'),
      'clause', initcap(p_nominatim_data->>'class')
    ));
  END IF;
  
  -- Add type as trait
  IF p_nominatim_data->>'type' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'type:' || lower(p_nominatim_data->>'type'),
      'clause', initcap(replace(p_nominatim_data->>'type', '_', ' '))
    ));
  END IF;

  -- Add country as trait
  IF v_address->>'country' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'country:' || lower(replace(v_address->>'country', ' ', '_')),
      'clause', v_address->>'country'
    ));
  END IF;

  RETURN v_traits;
END;
$$;


ALTER FUNCTION "game_logic"."extract_traits_from_nominatim" (JSONB) owner TO "postgres";


comment ON function "game_logic"."extract_traits_from_nominatim" (JSONB) IS 'Extract traits from Nominatim data.

Parameters:
- p_nominatim_data: JSONB from fetch_nominatim_place()

Process:
1. If features.use_llm_trait_extraction enabled, call LLM for rich trait extraction
2. Always add rule-based traits (class, type, country)

Returns: JSONB array of traits, each with:
- id: "category:value" format
- clause: Human readable description

Raises exception if LLM call fails (no fallback).';
