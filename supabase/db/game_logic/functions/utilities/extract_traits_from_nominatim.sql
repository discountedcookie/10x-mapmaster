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
  v_address JSONB;
  v_line TEXT;
  v_parts TEXT[];
  v_id TEXT;
  v_clause TEXT;
BEGIN
  v_address := COALESCE(p_nominatim_data->'address', '{}'::jsonb);

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
    -- Build summary of nominatim data for the LLM
    v_nominatim_summary := jsonb_build_object(
      'name', COALESCE(p_nominatim_data->'namedetails'->>'name:en', p_nominatim_data->>'name'),
      'display_name', p_nominatim_data->>'display_name',
      'class', p_nominatim_data->>'class',
      'type', p_nominatim_data->>'type',
      'country', v_address->>'country',
      'extratags', p_nominatim_data->'extratags',
      'address', v_address
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
