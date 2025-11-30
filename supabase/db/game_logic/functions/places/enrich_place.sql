-- Function: enrich_place
-- Category: places
-- Purpose: Enrich a place with traits from recent sessions
-- Note: This is a convenience wrapper. The main learning happens via trigger.
CREATE OR REPLACE FUNCTION "game_logic"."enrich_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_session_record RECORD;
  v_result JSONB := '[]'::JSONB;
  v_learn_result JSONB;
BEGIN
  -- Find recent successful sessions for this place and learn from them
  FOR v_session_record IN
    SELECT id
    FROM game_sessions
    WHERE place_id = p_place_id
      AND was_correct = TRUE
    ORDER BY created_at DESC
    LIMIT 5  -- Learn from last 5 successful sessions
  LOOP
    v_learn_result := learn_traits_from_session(v_session_record.id, p_place_id);
    v_result := v_result || jsonb_build_array(v_learn_result);
  END LOOP;
  
  RETURN jsonb_build_object(
    'status', 'success',
    'sessions_processed', jsonb_array_length(v_result),
    'results', v_result
  );
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "game_logic"."enrich_place" ("p_place_id" "uuid") IS 'Enriches a place by learning traits from recent successful game sessions.

This is a convenience wrapper that can be called manually.
The primary learning happens automatically via the enrich_place_on_session_complete trigger.

Processes up to 5 most recent successful sessions for the place.';
