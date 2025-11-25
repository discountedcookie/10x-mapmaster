-- Function: start_game
-- Category: game
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."start_game" (
  "p_description" "text",
  "p_language_code" "text" DEFAULT 'en'::"text"
) returns TABLE (session_id UUID) language "plpgsql"
SET
  search_path TO 'public' AS $$
DECLARE
  v_session_id uuid;
  v_candidates jsonb;
  v_description_embedding_id uuid;
BEGIN
  -- Rate limiting (anonymous users only)
  IF auth.role() = 'anonymous' THEN
    -- Advisory lock to prevent race condition (released at transaction end)
    PERFORM pg_advisory_xact_lock(hashtext(auth.uid()::text));
    
    IF EXISTS (
      SELECT 1 FROM game_sessions
      WHERE user_id = auth.uid()
      AND created_at > NOW() - INTERVAL '5 seconds'
    ) THEN
      RAISE EXCEPTION 'Rate limit exceeded: maximum 1 session per 5 seconds';
    END IF;
  END IF;

  -- Generate description embedding first
  v_description_embedding_id := get_or_create_embedding(p_description);
  
  -- Insert session with description embedding
  INSERT INTO game_sessions (
    user_id,
    description,
    description_language_code,
    description_embedding_id
  )
  VALUES (
    auth.uid(),
    p_description,
    p_language_code,
    v_description_embedding_id
  )
  RETURNING id INTO v_session_id;

  -- Get candidates
  SELECT candidates INTO v_candidates
  FROM get_candidates(v_session_id);

  -- Decide next turn
  PERFORM decide_next_turn(v_session_id, v_candidates);
  
  -- Return session_id
  RETURN QUERY SELECT v_session_id;
END;
$$;


ALTER FUNCTION "public"."start_game" ("p_description" "text", "p_language_code" "text") owner TO "postgres";


comment ON function "public"."start_game" ("p_description" "text", "p_language_code" "text") IS 'Starts a new game session with server-side embedding generation.

Parameters:
- p_description: User description of the place (max 500 chars)
- p_language_code: Language code (default: en)

Returns: session_id only. Frontend fetches full game state (including next_turn) from game_session_state view.

Process:
1. Generates embedding for description
2. Creates session in database
3. Calls decide_next_turn() to build initial next_turn JSONB with candidates

Security: Uses auth.uid() internally - no user_id parameter needed.

CONSERVATIVE GUESS POLICY:
- Guess when: (candidate_count = 1) OR (candidate_count <= 2 AND top_confidence >= 0.90 AND confidence_gap >= 0.15)
- Guard: If candidate_count <= 3 at start, force a guess (no questions needed)';
