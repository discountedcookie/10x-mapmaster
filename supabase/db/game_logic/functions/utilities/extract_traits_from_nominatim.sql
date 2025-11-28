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
  v_prompt_template TEXT;
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits JSONB;
  v_nominatim_summary JSONB;
  v_address_full JSONB;
  v_address JSONB;
  v_extratags JSONB;
  v_line TEXT;
  v_parts TEXT[];
  v_id TEXT;
  v_clause TEXT;
  -- Keys to remove from extratags (reference codes, URLs, numeric metadata)
  v_extratags_remove TEXT[] := ARRAY[
    'wikipedia', 'wikidata', 'website', 'url', 'image',
    'ref', 'ref:whc', 'ref:isil', 'ref:nrhp',
    'max_level', 'min_level', 'building:levels', 'building:levels:underground',
    'architect:wikidata', 'operator:wikidata', 'brand:wikidata',
    'phone', 'fax', 'email', 'contact:phone', 'contact:email',
    'opening_hours', 'check_date'
  ];
  -- Keys to remove from address (too granular for traits)
  v_address_remove TEXT[] := ARRAY[
    'postcode', 'house_number', 'road', 'neighbourhood', 'suburb',
    'borough', 'city_district', 'municipality', 'county',
    'ISO3166-2-lvl4', 'ISO3166-2-lvl6', 'country_code'
  ];
BEGIN
  v_address_full := COALESCE(p_nominatim_data->'address', '{}'::jsonb);
  v_extratags := COALESCE(p_nominatim_data->'extratags', '{}'::jsonb);

  -- Check if LLM is enabled
  v_llm_enabled := COALESCE(
    (game_logic.get_config('llm.enabled')#>>'{}')::BOOLEAN,
    TRUE
  );

  v_traits := '[]'::jsonb;
  
  -- ============================================================================
  -- LLM TRAIT EXTRACTION (if enabled)
  -- ============================================================================
  IF v_llm_enabled THEN
    -- Filter extratags: remove noisy keys
    FOR v_id IN SELECT unnest(v_extratags_remove)
    LOOP
      v_extratags := v_extratags - v_id;
    END LOOP;
    
    -- Filter address: keep only country, state, city for context
    v_address := jsonb_build_object(
      'country', v_address_full->>'country',
      'state', v_address_full->>'state',
      'city', COALESCE(v_address_full->>'city', v_address_full->>'town', v_address_full->>'village')
    );

    -- Build summary of nominatim data for the LLM
    v_nominatim_summary := jsonb_build_object(
      'name', COALESCE(p_nominatim_data->'namedetails'->>'name:en', p_nominatim_data->>'name'),
      'class', p_nominatim_data->>'class',
      'type', p_nominatim_data->>'type',
      'country', v_address_full->>'country',
      'extratags', v_extratags
    );

    -- Get prompt template from config and substitute
    v_prompt_template := game_logic.get_config_text('llm.trait_extraction.prompt');
    v_llm_prompt := replace(v_prompt_template, '{{nominatim_json}}', v_nominatim_summary::text);

    RAISE NOTICE 'Calling LLM for trait extraction: %', v_nominatim_summary->>'name';

    v_llm_response := game_logic.call_llm_api(v_llm_prompt, NULL, 'llm.trait_extraction');
    
    -- Parse line-based format: "id | clause" per line
    FOR v_line IN SELECT unnest(string_to_array(v_llm_response, E'\n'))
    LOOP
      v_line := trim(v_line);
      IF v_line <> '' AND v_line LIKE '%|%' THEN
        v_parts := string_to_array(v_line, '|');
        v_id := trim(v_parts[1]);
        v_clause := trim(v_parts[2]);
        IF v_id <> '' AND v_clause <> '' THEN
          v_traits := v_traits || jsonb_build_array(jsonb_build_object('id', v_id, 'clause', v_clause));
        END IF;
      END IF;
    END LOOP;
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
  IF v_address_full->>'country' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'country:' || lower(replace(v_address_full->>'country', ' ', '_')),
      'clause', v_address_full->>'country'
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
