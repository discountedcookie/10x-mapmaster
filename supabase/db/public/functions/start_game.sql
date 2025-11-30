-- Function: start_game
-- Category: game
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."start_game" (
  "p_description" "text",
  "p_language_code" "text" DEFAULT 'en'
) returns UUID language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session_id uuid;
  v_candidates jsonb;
  v_embedding_id uuid;
BEGIN
  -- Require authenticated (including Supabase anonymous) session
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Rate limiting via centralized check_rate_limit function
  -- Enforces limits from game_logic.config (default: 10 per minute)
  PERFORM game_logic.check_rate_limit('start_game');

  -- Generate description embedding first
  v_embedding_id := get_embedding(p_description);
  
  -- Insert session with description embedding
  INSERT INTO game_sessions (
    user_id,
    description,
    language_code,
    embedding_id
  )
  VALUES (
    auth.uid(),
    p_description,
    p_language_code,
    v_embedding_id
  )
  RETURNING id INTO v_session_id;

  -- Get candidates
  v_candidates := get_candidates(v_session_id);

  -- Decide next turn
  PERFORM decide_next_turn(v_session_id, v_candidates);
  
  RETURN v_session_id;
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
