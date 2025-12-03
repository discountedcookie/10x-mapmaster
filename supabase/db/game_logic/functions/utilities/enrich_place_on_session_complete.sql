-- Function: enrich_place_on_session_complete
-- Category: utilities
-- Purpose: Trigger function that enriches place with learned traits when a session completes
CREATE OR REPLACE FUNCTION "game_logic"."enrich_place_on_session_complete" () returns "trigger" language "plpgsql"
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when was_correct becomes TRUE
  IF NEW.was_correct = TRUE AND (OLD.was_correct IS NULL OR OLD.was_correct = FALSE) THEN
    -- Enqueue trait extraction asynchronously (pg_net fire-and-forget)
    PERFORM enqueue_trait_extraction(NEW.place_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place_on_session_complete" () owner TO "postgres";


comment ON function "game_logic"."enrich_place_on_session_complete" () IS 'Trigger function that enriches a place when a game session completes successfully.

When was_correct becomes TRUE, calls update_place_traits() to refresh all traits
using nominatim data, session descriptions, and game answers.

This enables the game to learn about places from successful games.';
