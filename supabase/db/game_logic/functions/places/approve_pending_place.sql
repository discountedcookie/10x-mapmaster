-- Function: approve_pending_place
-- Category: places
-- Purpose: Admin function to approve pending places (placeholder)
-- NOTE: Places don't have pending_review - sessions do. This function is for
-- direct place approval in case we add pending_review to places in future.
-- Currently returns success for any existing place.
CREATE OR REPLACE FUNCTION "game_logic"."approve_pending_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_place RECORD;
BEGIN
  -- Get place
  SELECT * INTO v_place FROM places WHERE id = p_place_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', p_place_id;
  END IF;

  -- Place exists - return success
  -- NOTE: Places table does not have pending_review column currently.
  -- Anonymous submissions go through game_sessions.pending_review instead.
  -- This function is kept for future extensibility.
  
  RETURN jsonb_build_object(
    'status', 'approved',
    'place_id', p_place_id,
    'name', v_place.name
  );
END;
$$;


ALTER FUNCTION "game_logic"."approve_pending_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "game_logic"."approve_pending_place" ("p_place_id" "uuid") IS 'Admin function for place approval.
NOTE: Currently places do not have pending_review - that is on game_sessions.
Use approve_pending_session trigger for anonymous submission approval.
This function returns success for any existing place.';
