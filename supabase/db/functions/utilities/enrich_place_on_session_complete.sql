-- Function: enrich_place_on_session_complete
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."enrich_place_on_session_complete" () returns "trigger" language "plpgsql" AS $$
BEGIN
  -- Only fire when was_correct becomes TRUE
  IF NEW.was_correct = TRUE AND (OLD.was_correct IS NULL OR OLD.was_correct = FALSE) THEN
    -- Run enrichment asynchronously (don't block session completion)
    PERFORM enrich_place(NEW.place_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."enrich_place_on_session_complete" () owner TO "postgres";
