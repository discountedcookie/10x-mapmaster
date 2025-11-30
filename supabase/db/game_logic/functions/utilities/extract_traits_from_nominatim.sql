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
  v_id TEXT;
  v_clause TEXT;
  -- Keys to EXCLUDE from extratags (blacklist - non-descriptive/operational data)
  v_extratags_exclude TEXT[] := ARRAY[
    -- External IDs and URLs (not descriptive)
    'wikidata', 'wikipedia', 'wikimedia_commons', 'website', 'url', 'image',
    -- Contact/operational info (not game-relevant)
    'phone', 'fax', 'email', 'opening_hours', 'check_date', 'fee',
    -- Administrative/source metadata
    'source', 'operator', 'brand', 'network', 'panoramax',
    -- Reference codes (cryptic, not descriptive)
    'ref', 'int_ref', 'nat_ref', 'loc_ref',
    -- Name variants (already have primary name)
    'alt_name', 'old_name', 'short_name', 'official_name', 'loc_name',
    -- Accessibility/service info (operational)
    'wheelchair', 'toilets', 'internet_access', 'smoking',
    -- Technical/rendering metadata
    'layer', '3dmr', 'min_height'
  ];
  v_key TEXT;
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
    -- Filter extratags: remove blacklisted keys (keep everything else)
    DECLARE
      v_filtered_extratags JSONB := '{}'::jsonb;
    BEGIN
      FOR v_key IN SELECT jsonb_object_keys(v_extratags)
      LOOP
        -- Exclude exact matches and prefix matches (e.g., 'contact:*', 'name:*', 'source:*')
        IF NOT (
          v_key = ANY(v_extratags_exclude) OR
          v_key LIKE 'contact:%' OR
          v_key LIKE 'name:%' OR
          v_key LIKE 'source:%' OR
          v_key LIKE 'ref:%' OR
          v_key LIKE 'payment:%' OR
          v_key LIKE 'addr:%' OR
          v_key LIKE 'image:%'
        ) THEN
          v_filtered_extratags := v_filtered_extratags || jsonb_build_object(v_key, v_extratags->v_key);
        END IF;
      END LOOP;
      v_extratags := v_filtered_extratags;
    END;
    
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

    v_llm_response := game_logic.call_llm_api(v_llm_prompt, 'json', 'llm.trait_extraction');
    
    -- Parse JSON format: {"traits": [{"id": "...", "clause": "..."}, ...]}
    BEGIN
      DECLARE
        v_json_response JSONB;
        v_trait JSONB;
      BEGIN
        v_json_response := v_llm_response::jsonb;
        
        -- Extract traits array from response
        FOR v_trait IN SELECT jsonb_array_elements(v_json_response->'traits')
        LOOP
          v_id := trim(v_trait->>'id');
          v_clause := trim(v_trait->>'clause');
          -- Normalize id: fix "category: value" -> "category:value", then spaces to hyphens, lowercase
          v_id := regexp_replace(v_id, ':\s+', ':', 'g');  -- Remove spaces after colons
          v_id := regexp_replace(v_id, '\s+', '-', 'g');   -- Replace remaining spaces with hyphens
          v_id := lower(v_id);
          IF v_id <> '' AND v_clause <> '' THEN
            v_traits := v_traits || jsonb_build_array(jsonb_build_object('id', v_id, 'clause', v_clause));
          END IF;
        END LOOP;
      END;
    EXCEPTION
      WHEN others THEN
        RAISE WARNING 'Failed to parse LLM JSON response: %. Response was: %', SQLERRM, v_llm_response;
    END;
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
1. Filter extratags: remove non-descriptive keys (wikidata, URLs, contact info, ref codes)
2. If LLM enabled, call LLM (gemma3:1b) with JSON format for rich trait extraction
3. Parse JSON response: {"traits": [{"id": "...", "clause": "..."}, ...]}
4. Always add rule-based traits (class, type, country)

Returns: JSONB array of traits, each with:
- id: "category:value" format (e.g., "style:victorian", "era:19th_century")
- clause: Human readable description

Logs warning if LLM JSON parsing fails, continues with rule-based traits only.';
