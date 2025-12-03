-- Function: play_turn
-- Category: game
-- Purpose: Route turn processing to appropriate handler (SRP - Router pattern)
-- REFACTORED: Extracted handlers for SRP and OCP compliance
CREATE OR REPLACE FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session_record RECORD;
BEGIN
  -- Require authenticated (including Supabase anonymous) session
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- ============================================================================
  -- RATE LIMITING
  -- ============================================================================
  -- Enforces limits from game_logic.config (default: 60 per minute)
  PERFORM game_logic.check_rate_limit('play_turn');

  -- ============================================================================
  -- VALIDATION & SESSION RETRIEVAL
  -- ============================================================================
  
  IF p_session_id IS NULL OR p_answer IS NULL THEN
    RAISE EXCEPTION 'Parameters cannot be null';
  END IF;

  -- Get session details (only columns needed by handlers)
  SELECT
    id,
    user_id,
    place_id,
    was_correct,
    next_turn,
    description,
    embedding_id
  INTO v_session_record
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;

  -- Ownership check (service_role may bypass)
  IF auth.role() <> 'service_role' AND v_session_record.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to modify this session';
  END IF;

  -- Validate session is active
  IF v_session_record.was_correct = TRUE THEN
    RAISE EXCEPTION 'Session % is already won', p_session_id;
  END IF;
  
  IF v_session_record.next_turn IS NULL THEN
    RAISE EXCEPTION 'Session % has no active turn', p_session_id;
  END IF;

  -- ============================================================================
  -- ROUTE TO APPROPRIATE HANDLER (SRP)
  -- ============================================================================

  IF v_session_record.next_turn->>'action' = 'guess' THEN
    PERFORM handle_guess(p_answer, v_session_record);
  ELSIF v_session_record.next_turn->>'action' = 'question' THEN
    PERFORM handle_question(p_answer, v_session_record);
  ELSE
    RAISE EXCEPTION 'Unknown action type: %', v_session_record.next_turn->>'action';
  END IF;
END;
$$;


ALTER FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) owner TO "postgres";


comment ON function "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) IS 'Router function for processing game turns (SRP pattern).

Responsibilities:
- Validate session state
- Route to appropriate handler based on action type:
  * guess → handle_guess()
  * question → handle_question()

SOLID principles:
- SRP: Each handler has single responsibility
- OCP: New action types can be added without modifying existing handlers
- DIP: Depends on abstractions (handler functions)

Returns: VOID (raises exception on error)
Frontend fetches full game state from game_session_state view after call.';
