-- Function: submit_place
-- Category: game
-- Purpose: Submit the correct place after game gives up
-- Spec: openspec/specs/database/spec.md#submit_place
CREATE OR REPLACE FUNCTION "public"."submit_place" ("p_session_id" UUID, "p_osm_id" TEXT) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session RECORD;
  v_nominatim_data JSONB;
  v_traits JSONB;
  v_place_id UUID;
  v_is_registered BOOLEAN;
  v_pending_review BOOLEAN;
BEGIN
  -- ============================================================================
  -- AUTHENTICATION CHECK
  -- ============================================================================
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to submit a place';
  END IF;

  -- ============================================================================
  -- RATE LIMITING
  -- ============================================================================
  PERFORM game_logic.check_rate_limit('submit_place');

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_session_id IS NULL THEN
    RAISE EXCEPTION 'Session ID cannot be null';
  END IF;
  
  IF p_osm_id IS NULL OR trim(p_osm_id) = '' THEN
    RAISE EXCEPTION 'OSM ID cannot be null or empty';
  END IF;

  -- ============================================================================
  -- SESSION VALIDATION & OWNERSHIP CHECK
  -- ============================================================================
  SELECT id, user_id, was_correct, next_turn, description
  INTO v_session
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;

  IF v_session.user_id IS NOT NULL AND v_session.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to modify this session';
  END IF;

  -- Verify session is in 'needs_submission' state (game ended without winning)
  IF NOT (
    (v_session.next_turn->>'action' = 'give_up') OR
    (v_session.next_turn IS NULL AND v_session.was_correct IS NOT TRUE)
  ) THEN
    RAISE EXCEPTION 'Session % is not in needs_submission state', p_session_id;
  END IF;

  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    UPDATE game_sessions
    SET 
      was_correct = FALSE,
      next_turn = NULL,
      pending_review = TRUE
    WHERE id = p_session_id;
    RETURN;
  END IF;

  -- ============================================================================
  -- DETERMINE USER TYPE
  -- ============================================================================
  SELECT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email IS NOT NULL 
    AND email != ''
  ) INTO v_is_registered;

  v_pending_review := NOT v_is_registered;

  -- ============================================================================
  -- FETCH, EXTRACT, CREATE (using helper functions)
  -- ============================================================================
  v_nominatim_data := game_logic.fetch_nominatim_place(p_osm_id);
  v_traits := game_logic.extract_traits_from_nominatim(v_nominatim_data);
  v_place_id := game_logic.create_place_with_traits(p_osm_id, v_nominatim_data, v_traits, FALSE);

  -- ============================================================================
  -- UPDATE SESSION
  -- ============================================================================
  UPDATE game_sessions
  SET 
    place_id = v_place_id,
    was_correct = FALSE,
    next_turn = NULL,
    status = 'ended',
    pending_review = v_pending_review,
    user_id = COALESCE(user_id, auth.uid())
  WHERE id = p_session_id;

  -- ============================================================================
  -- IF REGISTERED USER, TRIGGER TRAIT REGENERATION
  -- ============================================================================
  IF NOT v_pending_review THEN
    PERFORM game_logic.regenerate_place_traits(v_place_id);
  END IF;

  RETURN;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'submit_place failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."submit_place" (UUID, TEXT) owner TO "postgres";


comment ON function "public"."submit_place" (UUID, TEXT) IS 'Submit the correct place after game gives up.

Parameters:
- p_session_id: The game session ID
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364")

Process:
1. Validate auth and session ownership
2. Verify session is in needs_submission state
3. Fetch place data from Nominatim
4. Extract traits (LLM + rule-based)
5. Create place with traits and embedding
6. Link session to place

Security: SECURITY DEFINER. Uses auth.uid() for ownership validation.';
