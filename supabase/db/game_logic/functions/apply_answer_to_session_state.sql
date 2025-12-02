-- Function: apply_answer_to_session_state
-- Category: game
-- Applies a player's answer to the session state
-- Geographic questions affect bounding boxes via game_answers
CREATE OR REPLACE FUNCTION "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic AS $$
DECLARE
  v_session_record RECORD;
BEGIN
  -- Get current session state
  SELECT * INTO v_session_record
  FROM game_sessions gs
  WHERE gs.id = p_session_id;
  
  IF v_session_record.id IS NULL THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;
  
  -- Answer state is recorded in game_answers table
  -- Geographic filtering uses game_answers to determine bbox inclusion/exclusion
  -- No session state update needed here
END;
$$;


ALTER FUNCTION "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) owner TO "postgres";


comment ON function "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) IS 'Applies a user answer to the session.

Behavior:
- Answer state is recorded in game_answers table
- Geographic questions affect bounding boxes via game_answers
- Semantic questions affect candidate scoring via game_answers

Parameters:
- p_session_id: Session ID
- p_answer: User answer (yes/no/not_sure)
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
';
