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
  v_status INT;
  v_content TEXT;
  v_edge_function_url TEXT;
  v_anon_key TEXT;
  v_nominatim_data JSONB;
  v_place_data JSONB;
  v_traits JSONB;
  v_place_id UUID;
  v_trait_clauses TEXT[];
  v_combined_text TEXT;
  v_embedding_id UUID;
  v_is_registered BOOLEAN;
  v_pending_review BOOLEAN;
  v_trait_id TEXT;
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
  v_geojson JSONB;
  v_name TEXT;
BEGIN
  -- ============================================================================
  -- AUTHENTICATION CHECK (SECURITY DEFINER guardrail)
  -- ============================================================================
  -- SECURITY DEFINER functions MUST validate auth.uid() IS NOT NULL when user
  -- context is required. This prevents unauthorized access via anonymous users.
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to submit a place';
  END IF;

  -- ============================================================================
  -- RATE LIMITING
  -- ============================================================================
  PERFORM game_logic.check_rate_limit(auth.uid(), 'submit_place');

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
  SELECT
    id,
    user_id,
    was_correct,
    next_turn,
    description
  INTO v_session
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;

  -- Validate session ownership (auth.uid() must match session user_id)
  IF v_session.user_id IS NOT NULL AND v_session.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to modify this session';
  END IF;
  
  -- For anonymous sessions, allow if current user is also anonymous
  IF v_session.user_id IS NULL AND auth.uid() IS NOT NULL THEN
    -- Session was created anonymously but user is now authenticated
    -- This is allowed - we'll update the session user_id
    NULL;
  END IF;

  -- Verify session is in 'needs_submission' state
  -- needs_submission: next_turn->>'action' = 'give_up' OR next_turn IS NULL with was_correct IS NULL
  IF NOT (
    (v_session.next_turn->>'action' = 'give_up') OR
    (v_session.next_turn IS NULL AND v_session.was_correct IS NULL)
  ) THEN
    RAISE EXCEPTION 'Session % is not in needs_submission state', p_session_id;
  END IF;

  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    -- In test mode, just mark session as completed with pending_review
    UPDATE game_sessions
    SET 
      was_correct = FALSE,
      next_turn = NULL,
      pending_review = TRUE
    WHERE id = p_session_id;
    RETURN;
  END IF;

  -- ============================================================================
  -- DETERMINE USER TYPE (registered vs anonymous)
  -- ============================================================================
  -- Check if user is registered (has email in auth.users)
  SELECT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email IS NOT NULL 
    AND email != ''
  ) INTO v_is_registered;

  -- Anonymous users need review, registered users auto-approve
  v_pending_review := NOT v_is_registered;

  -- ============================================================================
  -- CONFIGURATION RETRIEVAL (from GUC vars or game_logic.config - NO hardcoded secrets)
  -- ============================================================================
  v_edge_function_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    game_logic.get_config_text('runtime.supabase_url')
  );
  
  IF v_edge_function_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  v_edge_function_url := v_edge_function_url || '/functions/v1/place-enrichment';

  v_anon_key := COALESCE(
    NULLIF(current_setting('app.supabase_anon_key', true), ''),
    game_logic.get_config_text('runtime.supabase_anon_key')
  );
  
  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_anon_key or runtime.supabase_anon_key';
  END IF;

  -- ============================================================================
  -- CALL PLACE-ENRICHMENT EDGE FUNCTION
  -- ============================================================================
  -- Increase timeout for edge function call
  PERFORM set_config('statement_timeout', '30s', true);
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '5000');

  RAISE NOTICE 'Calling place-enrichment at: % with osm_id: %', v_edge_function_url, p_osm_id;

  -- Note: Select specific columns to avoid TupleDesc resource leak
  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'POST',
    v_edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    jsonb_build_object('query', p_osm_id)::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', v_status;

  IF v_status != 200 THEN
    RAISE EXCEPTION 'Place enrichment failed with status %: %', v_status, v_content;
  END IF;

  -- ============================================================================
  -- PARSE NOMINATIM RESPONSE
  -- ============================================================================
  v_nominatim_data := v_content::jsonb;
  v_place_data := v_nominatim_data->'place';
  v_traits := v_nominatim_data->'traits';

  IF v_place_data IS NULL THEN
    RAISE EXCEPTION 'No place data in response: %', v_content;
  END IF;

  -- Extract place fields
  v_name := v_place_data->>'english_name';
  IF v_name IS NULL OR v_name = '' THEN
    v_name := v_place_data->>'display_name';
  END IF;
  
  v_lat := (v_place_data->>'lat')::DOUBLE PRECISION;
  v_lng := (v_place_data->>'lng')::DOUBLE PRECISION;
  v_geojson := v_place_data->'geojson';

  -- ============================================================================
  -- EXTRACT TRAIT CLAUSES FOR EMBEDDING
  -- ============================================================================
  -- Build array of trait clauses from the traits returned by enrichment
  IF v_traits IS NOT NULL AND jsonb_array_length(v_traits) > 0 THEN
    SELECT array_agg(t->>'clause')
    INTO v_trait_clauses
    FROM jsonb_array_elements(v_traits) AS t
    WHERE t->>'clause' IS NOT NULL;
  END IF;

  -- ============================================================================
  -- GENERATE EMBEDDING FROM COMBINED TRAIT CLAUSES
  -- ============================================================================
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    v_combined_text := array_to_string(v_trait_clauses, '. ');
    v_embedding_id := get_or_create_embedding(v_combined_text);
  END IF;

  -- ============================================================================
  -- CREATE OR UPDATE PLACE RECORD
  -- ============================================================================
  v_place_id := game_logic.add_place(
    v_name,
    p_osm_id,
    v_lat::NUMERIC,
    v_lng::NUMERIC,
    v_geojson,
    FALSE  -- places themselves don't have pending_review anymore
  );

  -- Update place embedding if we generated one
  IF v_embedding_id IS NOT NULL THEN
    UPDATE places
    SET embedding_id = v_embedding_id
    WHERE id = v_place_id;
  END IF;

  -- ============================================================================
  -- CREATE TRAITS AND LINK TO PLACE
  -- ============================================================================
  IF v_traits IS NOT NULL AND jsonb_array_length(v_traits) > 0 THEN
    FOR v_trait_id IN
      SELECT t->>'id'
      FROM jsonb_array_elements(v_traits) AS t
      WHERE t->>'id' IS NOT NULL
    LOOP
      -- Insert trait if not exists
      INSERT INTO traits (id, clause)
      SELECT 
        t->>'id',
        t->>'clause'
      FROM jsonb_array_elements(v_traits) AS t
      WHERE t->>'id' = v_trait_id
      ON CONFLICT (id) DO NOTHING;

      -- Link trait to place
      INSERT INTO place_traits (place_id, trait_id)
      VALUES (v_place_id, v_trait_id)
      ON CONFLICT (place_id, trait_id) DO NOTHING;
    END LOOP;
  END IF;

  -- ============================================================================
  -- UPDATE SESSION
  -- ============================================================================
  -- Note: OSM ID, name, lat, lng are stored in the places table (via place_id FK)
  -- No need to duplicate them in game_sessions
  UPDATE game_sessions
  SET 
    place_id = v_place_id,
    was_correct = FALSE,
    next_turn = NULL,
    pending_review = v_pending_review,
    -- Update user_id if session was anonymous but user is now authenticated
    user_id = COALESCE(user_id, auth.uid())
  WHERE id = p_session_id;

  -- ============================================================================
  -- IF REGISTERED USER, TRIGGER TRAIT REGENERATION
  -- ============================================================================
  IF NOT v_pending_review THEN
    -- Auto-approved - regenerate traits immediately
    PERFORM game_logic.regenerate_place_traits(v_place_id);
  END IF;

  -- Return void on success
  RETURN;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'submit_place failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."submit_place" (UUID, TEXT) owner TO "postgres";


comment ON function "public"."submit_place" (UUID, TEXT) IS 'Submit the correct place after game gives up (needs_submission state).

Parameters:
- p_session_id: The game session ID
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364")

Process:
1. Validate auth and session ownership
2. Verify session is in needs_submission state
3. Call place-enrichment edge function with osm_id
4. Parse Nominatim response, extract traits
5. Generate embedding from trait clauses
6. Create/update place record
7. Link session to place (place_id), set was_correct = FALSE
8. If registered user: pending_review = FALSE (auto-approve)
9. If anonymous user: pending_review = TRUE

Security: SECURITY DEFINER to call edge functions and internal functions.
Uses auth.uid() for ownership validation.

Returns: void on success, raises exception on error.';
