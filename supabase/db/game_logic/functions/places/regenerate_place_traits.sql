-- Function: regenerate_place_traits
-- Category: places
-- Purpose: Regenerate traits for a place from all approved sessions
-- Spec: openspec/specs/database/spec.md#learning-triggers
CREATE OR REPLACE FUNCTION "game_logic"."regenerate_place_traits" ("p_place_id" UUID) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place RECORD;
  v_session_descriptions TEXT[];
  v_combined_context TEXT;
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits_json JSONB;
  v_trait RECORD;
  v_trait_clauses TEXT[];
  v_combined_traits TEXT;
  v_embedding_id UUID;
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
    -- Skip LLM calls in tests
    RETURN;
  END IF;

  -- ============================================================================
  -- GET PLACE DATA
  -- ============================================================================
  SELECT
    id,
    name,
    osm_id,
    lat,
    lng
  INTO v_place
  FROM places
  WHERE id = p_place_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place % not found', p_place_id;
  END IF;

  -- ============================================================================
  -- QUERY ALL APPROVED SESSIONS FOR THIS PLACE
  -- ============================================================================
  SELECT array_agg(DISTINCT description)
  INTO v_session_descriptions
  FROM game_sessions
  WHERE place_id = p_place_id
    AND pending_review = FALSE;

  -- ============================================================================
  -- BUILD CONTEXT FOR LLM
  -- ============================================================================
  v_combined_context := format(
    'Place: %s
Location: (%.6f, %.6f)
OSM ID: %s',
    v_place.name,
    v_place.lat,
    v_place.lng,
    v_place.osm_id
  );

  -- Add session descriptions if available
  IF v_session_descriptions IS NOT NULL AND array_length(v_session_descriptions, 1) > 0 THEN
    v_combined_context := v_combined_context || E'\n\nUser descriptions from gameplay:\n- ' 
      || array_to_string(v_session_descriptions, E'\n- ');
  END IF;

  -- ============================================================================
  -- CALL LLM TO EXTRACT TRAITS
  -- ============================================================================
  v_llm_prompt := format(
    'Extract traits for this place. Return a JSON array of trait objects.

Each trait must have:
- id: snake_case identifier (e.g., "is_tourist_attraction", "has_religious_significance")
- clause: human-readable description (e.g., "Is a major tourist attraction")
- category: one of "type", "feature", "cultural", "geographic", "historical"

%s

Return ONLY a valid JSON array. Example format:
[
  {"id": "is_historic_monument", "clause": "Is a historic monument", "category": "type"},
  {"id": "attracts_tourists", "clause": "Attracts many tourists", "category": "cultural"}
]

Extract 5-15 relevant traits based on the place data and descriptions.',
    v_combined_context
  );

  -- Call LLM API
  v_llm_response := game_logic.call_llm_api(v_llm_prompt, 'json');

  -- ============================================================================
  -- PARSE LLM RESPONSE
  -- ============================================================================
  BEGIN
    -- Try to parse as JSON array
    v_traits_json := v_llm_response::jsonb;
    
    -- Validate it's an array
    IF jsonb_typeof(v_traits_json) != 'array' THEN
      RAISE EXCEPTION 'LLM response is not a JSON array';
    END IF;
  EXCEPTION
    WHEN others THEN
      -- Log error but don't fail - keep existing traits
      RAISE WARNING 'Failed to parse LLM trait response: %', SQLERRM;
      RETURN;
  END;

  -- ============================================================================
  -- DELETE EXISTING PLACE_TRAITS
  -- ============================================================================
  DELETE FROM place_traits
  WHERE place_id = p_place_id;

  -- ============================================================================
  -- INSERT NEW TRAITS AND LINKS
  -- ============================================================================
  FOR v_trait IN
    SELECT
      t->>'id' AS id,
      t->>'clause' AS clause
    FROM jsonb_array_elements(v_traits_json) AS t
    WHERE t->>'id' IS NOT NULL
      AND t->>'clause' IS NOT NULL
  LOOP
    -- Insert trait if not exists
    INSERT INTO traits (id, clause)
    VALUES (v_trait.id, v_trait.clause)
    ON CONFLICT (id) DO UPDATE SET
      clause = EXCLUDED.clause;

    -- Link trait to place
    INSERT INTO place_traits (place_id, trait_id)
    VALUES (p_place_id, v_trait.id)
    ON CONFLICT (place_id, trait_id) DO NOTHING;

    -- Collect trait clauses for embedding
    v_trait_clauses := array_append(v_trait_clauses, v_trait.clause);
  END LOOP;

  -- ============================================================================
  -- REGENERATE PLACE EMBEDDING FROM COMBINED TRAIT CLAUSES
  -- ============================================================================
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    v_combined_traits := array_to_string(v_trait_clauses, '. ');
    v_embedding_id := get_or_create_embedding(v_combined_traits);

    UPDATE places
    SET 
      embedding_id = v_embedding_id,
      updated_at = NOW()
    WHERE id = p_place_id;
  END IF;

  RAISE NOTICE 'Regenerated % traits for place %', 
    COALESCE(array_length(v_trait_clauses, 1), 0), v_place.name;

  RETURN;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'regenerate_place_traits failed for place %: %', p_place_id, SQLERRM;
    -- Don't re-raise - allow trigger to complete
    RETURN;
END;
$$;


ALTER FUNCTION "game_logic"."regenerate_place_traits" (UUID) owner TO "postgres";


comment ON function "game_logic"."regenerate_place_traits" (UUID) IS 'Regenerate traits for a place from all approved sessions.

Parameters:
- p_place_id: The place ID to regenerate traits for

Process:
1. Query all approved sessions for the place (pending_review = FALSE)
2. Get place Nominatim data (name, location)
3. Combine place data with all session descriptions
4. Call LLM to extract complete trait list
5. Delete existing place_traits for the place
6. Insert new traits (create in traits table if needed)
7. Insert new place_traits links
8. Regenerate place embedding from combined trait clauses

Called by:
- Trigger: on_session_approval_regenerate_traits (when session.pending_review → FALSE)
- Manual: Admin can call to refresh traits

Security: SECURITY DEFINER to access game_logic functions and call LLM.

Note: Failures are logged as warnings but don''t fail the transaction,
allowing the approval to complete even if trait regeneration fails.';
