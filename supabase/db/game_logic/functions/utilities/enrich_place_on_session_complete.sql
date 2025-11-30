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
    -- Learn from the completed session's answers (existing traits)
    PERFORM learn_traits_from_session(NEW.id, NEW.place_id);
    
    -- Extract NEW traits from session description via LLM
    PERFORM regenerate_place_traits(NEW.place_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place_on_session_complete" () owner TO "postgres";


comment ON function "game_logic"."enrich_place_on_session_complete" () IS 'Trigger function that enriches a place when a game session completes successfully.

When was_correct becomes TRUE:
1. Calls learn_traits_from_session to add affirmed traits to the place
2. Calls regenerate_place_traits to extract NEW traits from session description via LLM

This enables the game to learn new traits about places from successful games.';
