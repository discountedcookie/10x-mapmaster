-- Function: regenerate_place_traits
-- Category: places
-- Purpose: Add new traits to a place from session descriptions (ADDITIVE)
-- Spec: openspec/specs/database/spec.md#learning-triggers
CREATE OR REPLACE FUNCTION "game_logic"."regenerate_place_traits" ("p_place_id" UUID) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place RECORD;
  v_session_descriptions TEXT[];
  v_existing_traits TEXT[];
  v_combined_context TEXT;
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits_json JSONB;
  v_trait RECORD;
  v_trait_clauses TEXT[];
  v_combined_traits TEXT;
  v_embedding_id UUID;
  v_trait_embedding_id UUID;
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
  -- QUERY EXISTING TRAITS FOR THIS PLACE
  -- ============================================================================
  SELECT array_agg(t.clause)
  INTO v_existing_traits
  FROM place_traits pt
  JOIN traits t ON t.id = pt.trait_id
  WHERE pt.place_id = p_place_id;

  -- ============================================================================
  -- BUILD CONTEXT FOR LLM
  -- ============================================================================
  v_combined_context := format(
    'Place: %s
Location: (%s, %s)
OSM ID: %s',
    v_place.name,
    round(v_place.lat::numeric, 6),
    round(v_place.lng::numeric, 6),
    v_place.osm_id
  );

  -- Add existing traits if available (so LLM can identify NEW traits only)
  IF v_existing_traits IS NOT NULL AND array_length(v_existing_traits, 1) > 0 THEN
    v_combined_context := v_combined_context || E'\n\nExisting traits (already known):\n- ' 
      || array_to_string(v_existing_traits, E'\n- ');
  END IF;

  -- Add session descriptions if available
  IF v_session_descriptions IS NOT NULL AND array_length(v_session_descriptions, 1) > 0 THEN
    v_combined_context := v_combined_context || E'\n\nUser descriptions from gameplay:\n- ' 
      || array_to_string(v_session_descriptions, E'\n- ');
  END IF;

  -- ============================================================================
  -- CALL LLM TO EXTRACT TRAITS
  -- ============================================================================
  v_llm_prompt := format(
    'Extract NEW traits for this place that are not already in the existing traits list.

Each trait must have:
- id: snake_case identifier (e.g., "is_tourist_attraction", "has_religious_significance")
- clause: human-readable description (e.g., "Is a major tourist attraction")
- category: one of "type", "feature", "cultural", "geographic", "historical"

%s

IMPORTANT: Only extract traits that are NOT already in the "Existing traits" list above.
Focus on new information from the user descriptions.

Return ONLY a valid JSON array. Return an empty array [] if no new traits are found.
Example format:
[
  {"id": "is_historic_monument", "clause": "Is a historic monument", "category": "type"},
  {"id": "attracts_tourists", "clause": "Attracts many tourists", "category": "cultural"}
]',
    v_combined_context
  );

  -- Call LLM API with extraction config (no stop sequences for JSON arrays)
  v_llm_response := game_logic.call_llm_api(v_llm_prompt, 'json', 'llm.trait_extraction');

  -- ============================================================================
  -- PARSE LLM RESPONSE
  -- ============================================================================
  BEGIN
    -- Try to parse as JSON array
    v_traits_json := v_llm_response::jsonb;
    
    -- If LLM returned a single object, wrap it in an array
    IF jsonb_typeof(v_traits_json) = 'object' THEN
      v_traits_json := jsonb_build_array(v_traits_json);
    ELSIF jsonb_typeof(v_traits_json) != 'array' THEN
      RAISE EXCEPTION 'LLM response is not a JSON array or object';
    END IF;
  EXCEPTION
    WHEN others THEN
      -- Log error but don't fail - mark place as approved but keep existing traits
      RAISE WARNING 'Failed to parse LLM trait response: %', SQLERRM;
      UPDATE places
      SET 
        pending_review = FALSE,
        updated_at = NOW()
      WHERE id = p_place_id;
      RETURN;
  END;

  -- ============================================================================
  -- INSERT/MERGE TRAITS (ADDITIVE - preserves existing traits)
  -- ============================================================================
  -- NOTE: We do NOT delete existing place_traits. This function ADDS new traits
  -- discovered from session descriptions while preserving traits learned from:
  -- 1. Initial Nominatim extraction
  -- 2. Previous LLM extractions
  -- 3. Game session learning (learn_traits_from_session)
  -- ============================================================================
  FOR v_trait IN
    SELECT
      t->>'id' AS id,
      t->>'clause' AS clause
    FROM jsonb_array_elements(v_traits_json) AS t
    WHERE t->>'id' IS NOT NULL
      AND t->>'clause' IS NOT NULL
  LOOP
    -- Generate embedding for trait clause and upsert trait
    v_trait_embedding_id := get_embedding(v_trait.clause);

    -- Upsert trait: preserve existing clause if present, only fill in nulls
    INSERT INTO traits (id, clause, embedding_id)
    VALUES (v_trait.id, v_trait.clause, v_trait_embedding_id)
    ON CONFLICT (id) DO UPDATE SET
      clause = COALESCE(traits.clause, EXCLUDED.clause),
      embedding_id = COALESCE(traits.embedding_id, EXCLUDED.embedding_id);

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
    v_embedding_id := get_embedding(v_combined_traits);

    UPDATE places
    SET 
      embedding_id = v_embedding_id,
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;
  ELSE
    -- Even without traits, mark place as approved
    UPDATE places
    SET 
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;
  END IF;

  RAISE NOTICE 'Added % new traits for place %', 
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


comment ON function "game_logic"."regenerate_place_traits" (UUID) IS 'Add new traits to a place from session descriptions (ADDITIVE - preserves existing).

Parameters:
- p_place_id: The place ID to enrich with new traits

Process:
1. Query all approved sessions for the place (pending_review = FALSE)
2. Query existing traits for the place (to avoid duplicates)
3. Get place Nominatim data (name, location)
4. Combine place data, existing traits, and session descriptions
5. Call LLM to extract NEW traits not already in existing list
6. Insert new traits (preserves existing trait clauses via COALESCE)
7. Insert new place_traits links (ON CONFLICT DO NOTHING)
8. Update place embedding from combined NEW trait clauses

IMPORTANT: This function is ADDITIVE. It does NOT delete existing traits.
Traits accumulate over time from:
- Initial Nominatim extraction
- Previous LLM extractions  
- Game session learning (learn_traits_from_session)

Called by:
- Trigger: on_session_approval_regenerate_traits (when session.pending_review → FALSE)
- Manual: Admin can call to add traits from session descriptions

Security: SECURITY DEFINER to access game_logic functions and call LLM.

Note: Failures are logged as warnings but don''t fail the transaction,
allowing the approval to complete even if trait extraction fails.';
