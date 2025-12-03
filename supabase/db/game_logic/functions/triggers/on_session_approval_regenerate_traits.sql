-- Trigger Function: on_session_approval_regenerate_traits
-- Schema: game_logic
-- Purpose: Triggers trait update when a session is approved
-- Fires when game_sessions.pending_review changes from TRUE to FALSE
CREATE OR REPLACE FUNCTION "game_logic"."on_session_approval_regenerate_traits" () returns trigger language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when pending_review changes from TRUE to FALSE
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Only update traits if session has a linked place
    IF NEW.place_id IS NOT NULL THEN
      PERFORM game_logic.enqueue_trait_extraction(NEW.place_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."on_session_approval_regenerate_traits" () owner TO "postgres";


comment ON function "game_logic"."on_session_approval_regenerate_traits" () IS 'Trigger function that fires when game_sessions.pending_review changes from TRUE to FALSE.
Calls update_place_traits() to refresh place traits based on all available data.';
