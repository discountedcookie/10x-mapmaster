-- Function: approve_pending_session
-- Category: utilities
-- Purpose: Trigger to process approved place submissions
-- When pending_review changes from TRUE to FALSE on places, marks place as approved
CREATE OR REPLACE FUNCTION "game_logic"."approve_pending_session" () returns "trigger" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when pending_review becomes false
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Place is now approved - no additional action needed
    -- The place record already exists with all required data
    NULL;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."approve_pending_session" () owner TO "postgres";


comment ON function "game_logic"."approve_pending_session" () IS 'Trigger function for processing approved place submissions.
When places.pending_review changes from TRUE to FALSE, the place is marked as approved.';
