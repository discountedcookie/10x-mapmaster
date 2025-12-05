-- Function: update_place_traits
-- Category: places
-- Purpose: Unified trait extraction/update for a place
-- Replaces: extract_traits_from_nominatim, regenerate_place_traits
CREATE OR REPLACE FUNCTION "game_logic"."update_place_traits" ("p_place_id" UUID) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place RECORD;
  v_nominatim_data JSONB;
  v_nominatim_summary JSONB;
  v_session_descriptions TEXT[];
  v_game_answers TEXT[];
  v_existing_traits TEXT[];
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits_json JSONB;
  v_trait RECORD;
  v_trait_id UUID;
  v_trait_clauses TEXT[];
  v_trait_embedding_id UUID;
  v_max_traits INT;
   v_extratags JSONB;
   v_filtered_extratags JSONB := '{}'::jsonb;
   v_nominatim_text TEXT := '';
   v_address JSONB;
   v_key TEXT;
  v_extratags_exclude TEXT[] := ARRAY[
    'wikidata', 'wikipedia', 'wikimedia_commons', 'website', 'url', 'image',
    'phone', 'fax', 'email', 'opening_hours', 'check_date', 'fee',
    'source', 'operator', 'brand', 'network', 'panoramax',
    'ref', 'int_ref', 'nat_ref', 'loc_ref',
    'alt_name', 'old_name', 'short_name', 'official_name', 'loc_name',
    'wheelchair', 'toilets', 'internet_access', 'smoking',
    'layer', '3dmr', 'min_height'
  ];
BEGIN
  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_place_id IS NULL THEN
    RAISE EXCEPTION 'Place ID cannot be null';
  END IF;

  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    RETURN;
  END IF;

  -- Check if LLM is enabled
  IF NOT COALESCE((game_logic.get_config('llm.enabled')#>>'{}')::BOOLEAN, TRUE) THEN
    RETURN;
  END IF;

  -- ============================================================================
  -- GET PLACE DATA
  -- ============================================================================
  SELECT id, name, osm_id, lat, lng
  INTO v_place
  FROM places
  WHERE id = p_place_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place % not found', p_place_id;
  END IF;

  -- ============================================================================
  -- FETCH NOMINATIM DATA (if place has osm_id)
  -- ============================================================================
  IF v_place.osm_id IS NOT NULL THEN
    BEGIN
      v_nominatim_data := game_logic.fetch_nominatim_place(v_place.osm_id);
    EXCEPTION WHEN others THEN
      RAISE WARNING 'Failed to fetch Nominatim data for %: %', v_place.osm_id, SQLERRM;
      v_nominatim_data := '{}'::jsonb;
    END;
  ELSE
    v_nominatim_data := '{}'::jsonb;
  END IF;

  -- Filter extratags
  v_extratags := COALESCE(v_nominatim_data->'extratags', '{}'::jsonb);
  FOR v_key IN SELECT jsonb_object_keys(v_extratags)
  LOOP
    IF NOT (
      v_key = ANY(v_extratags_exclude) OR
      v_key LIKE 'contact:%' OR v_key LIKE 'name:%' OR v_key LIKE 'source:%' OR
      v_key LIKE 'ref:%' OR v_key LIKE 'payment:%' OR v_key LIKE 'addr:%' OR v_key LIKE 'image:%'
    ) THEN
      v_filtered_extratags := v_filtered_extratags || jsonb_build_object(v_key, v_extratags->v_key);
    END IF;
   END LOOP;

   -- Build nominatim text for LLM (human-readable format)
   v_nominatim_text := 'category: ' || COALESCE(v_nominatim_data->>'class', 'unknown') || '/' || COALESCE(v_nominatim_data->>'type', 'unknown') || E'\n';
   FOR v_key IN SELECT jsonb_object_keys(v_filtered_extratags)
   LOOP
     v_nominatim_text := v_nominatim_text || v_key || ': ' || (v_filtered_extratags->>v_key) || E'\n';
   END LOOP;

   v_address := COALESCE(v_nominatim_data->'address', '{}'::jsonb);

   -- Build nominatim summary for LLM (kept for potential future use)
   v_nominatim_summary := jsonb_build_object(
     'class', v_nominatim_data->>'class',
     'type', v_nominatim_data->>'type',
     'extratags', v_filtered_extratags
   );

  -- ============================================================================
  -- GATHER CONTEXT
  -- ============================================================================
  
  -- Get session descriptions
  SELECT array_agg(DISTINCT description)
  INTO v_session_descriptions
  FROM game_sessions
  WHERE place_id = p_place_id
    AND description IS NOT NULL;

  -- Get game answers (trait-based answers from sessions)
  SELECT array_agg(
    CASE 
      WHEN ga.answer = 'yes' THEN '+ ' || COALESCE(t.clause, gr.name)
      WHEN ga.answer = 'no' THEN '- ' || COALESCE(t.clause, gr.name)
      ELSE '? ' || COALESCE(t.clause, gr.name)
    END
  )
  INTO v_game_answers
  FROM game_sessions gs
  JOIN game_answers ga ON ga.session_id = gs.id
  LEFT JOIN traits t ON t.id = ga.trait_id
  LEFT JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE gs.place_id = p_place_id
    AND gs.was_correct = TRUE;

  -- Get existing traits (just clauses, no IDs)
  SELECT array_agg(t.clause)
  INTO v_existing_traits
  FROM place_traits pt
  JOIN traits t ON t.id = pt.trait_id
  WHERE pt.place_id = p_place_id;

  -- Get max traits from config
  v_max_traits := COALESCE(get_config_int('llm.trait_extraction.max_traits'), 20);

  -- ============================================================================
  -- BUILD LLM PROMPT
  -- ============================================================================
  v_llm_prompt := get_config_text('llm.trait_extraction.prompt');
   v_llm_prompt := replace(v_llm_prompt, '{place_name}', COALESCE(v_place.name, 'Unknown'));
   v_llm_prompt := replace(v_llm_prompt, '{lat}', round(v_place.lat::numeric, 4)::text);
   v_llm_prompt := replace(v_llm_prompt, '{lng}', round(v_place.lng::numeric, 4)::text);
   v_llm_prompt := replace(v_llm_prompt, '{country}', COALESCE(v_address->>'country', 'Unknown'));
   v_llm_prompt := replace(v_llm_prompt, '{place_type}', COALESCE(v_nominatim_data->>'type', 'Unknown'));
   v_llm_prompt := replace(v_llm_prompt, '{nominatim_text}', COALESCE(v_nominatim_text, 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{existing_traits}', COALESCE(array_to_string(v_existing_traits, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{session_descriptions}', COALESCE(array_to_string(v_session_descriptions, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{game_answers}', COALESCE(array_to_string(v_game_answers, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{max_traits}', v_max_traits::text);

  RAISE NOTICE 'Updating traits for place: %', v_place.name;
  RAISE NOTICE 'Trait extraction prompt: %', v_llm_prompt;

  -- ============================================================================
  -- CALL LLM
  -- ============================================================================
  v_llm_response := game_logic.call_llm_api(v_llm_prompt, 'json', 'llm.trait_extraction');
  
  RAISE NOTICE 'LLM trait response: %', v_llm_response;

   -- ============================================================================
   -- PARSE RESPONSE
   -- ============================================================================
   BEGIN
     v_traits_json := v_llm_response::jsonb;
     
     -- Handle new format: {"traits": [...], "changes": "..."}
     IF jsonb_typeof(v_traits_json) = 'object' THEN
       -- Log changes field if present (for debugging)

       -- Extract traits array
       IF v_traits_json ? 'traits' THEN
         v_traits_json := v_traits_json->'traits';
       ELSE
         RAISE EXCEPTION 'Response object must have "traits" array';
       END IF;
     ELSIF jsonb_typeof(v_traits_json) != 'array' THEN
       -- Backward compatibility: if it's not an array and not an object, fail
       RAISE EXCEPTION 'Response must be {"traits": [...]} or an array';
     END IF;
   EXCEPTION
     WHEN others THEN
       RAISE WARNING 'Failed to parse LLM trait response: %. Response: %', SQLERRM, left(v_llm_response, 200);
       RETURN;
   END;

   -- ============================================================================
   -- REPLACE TRAITS (LLM curates the full list)
   -- ============================================================================
   
   -- Delete existing traits for this place (LLM output is authoritative)
   DELETE FROM place_traits WHERE place_id = p_place_id;
   
   -- Insert curated traits
  FOR v_trait IN
    SELECT t AS clause
    FROM jsonb_array_elements_text(v_traits_json) AS t
    WHERE length(trim(t)) > 1
      AND length(trim(t)) <= 500
    LIMIT v_max_traits
  LOOP
    -- Generate embedding for trait clause (use 'passage' since traits are matched against queries)
    v_trait_embedding_id := get_embedding(v_trait.clause, 'passage');

    -- Insert trait with generated UUID (deduplication happens via embedding_id)
    INSERT INTO traits (id, clause, embedding_id)
    VALUES (gen_random_uuid(), v_trait.clause, v_trait_embedding_id)
    ON CONFLICT (embedding_id) DO UPDATE SET
      clause = EXCLUDED.clause
    RETURNING id INTO v_trait_id;

    -- Link trait to place
    INSERT INTO place_traits (place_id, trait_id)
    VALUES (p_place_id, v_trait_id)
    ON CONFLICT (place_id, trait_id) DO NOTHING;

    -- Collect for place embedding
    v_trait_clauses := array_append(v_trait_clauses, v_trait.clause);
  END LOOP;

  -- ============================================================================
  -- UPDATE PLACE STATUS
  -- ============================================================================
  -- Note: Place embedding is NOT updated here - algorithm uses individual trait embeddings.
  -- Place embedding only exists as fallback for legacy data without trait embeddings.
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    UPDATE places
    SET 
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;

    RAISE NOTICE 'Updated % traits for place %', array_length(v_trait_clauses, 1), v_place.name;
  ELSE
    UPDATE places
    SET 
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;

    RAISE WARNING 'No traits extracted for place %', v_place.name;
  END IF;

EXCEPTION
  WHEN others THEN
    RAISE WARNING 'update_place_traits failed for place %: %', p_place_id, SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."update_place_traits" (UUID) owner TO "postgres";


comment ON function "game_logic"."update_place_traits" (UUID) IS 'Unified trait extraction and update for a place.

Gathers all available context:
- Nominatim data (class, type, extratags)
- Existing traits
- Session descriptions from gameplay
- Game answers (yes/no responses)

Calls LLM to curate the best traits for the place (up to max_traits).
The LLM reviews existing traits, adds new facts, removes generic/duplicate info,
and returns the authoritative list. Existing traits are replaced with LLM output.

Called by:
- create_place_with_traits (initial creation)
- Trigger after session approval
- Manual enrichment

Replaces: extract_traits_from_nominatim, regenerate_place_traits';
