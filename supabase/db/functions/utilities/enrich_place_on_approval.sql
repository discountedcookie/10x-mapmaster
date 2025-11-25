-- Function: enrich_place_on_approval
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."enrich_place_on_approval" () returns "trigger" language "plpgsql" AS $$
BEGIN
  -- Only fire when pending_review becomes FALSE
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Run enrichment
    PERFORM enrich_place(NEW.id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."enrich_place_on_approval" () owner TO "postgres";
