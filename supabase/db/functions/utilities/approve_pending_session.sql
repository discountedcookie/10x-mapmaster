-- Function: approve_pending_session
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."approve_pending_session" () returns "trigger" language "plpgsql" security definer AS $$
DECLARE
  place_id_val UUID;
BEGIN
  -- Only fire when pending_review becomes false and submitted_nominatim_id is not null
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE AND NEW.submitted_nominatim_id IS NOT NULL THEN
    -- Upsert into places by nominatim_place_id
    INSERT INTO places (
      name, lat, lng, nominatim_place_id,
      canonical_description, semantic_constraint,
      language_code, geom
    )
    VALUES (
      NEW.submitted_place_name,
      NEW.submitted_lat,
      NEW.submitted_lng,
      NEW.submitted_nominatim_id,
      NEW.description,
      NEW.semantic_constraint,
      NEW.description_language_code,
      ST_SetSRID(ST_MakePoint(NEW.submitted_lng, NEW.submitted_lat), 4326)
    )
    ON CONFLICT (nominatim_place_id)
    DO UPDATE SET
      canonical_description = COALESCE(EXCLUDED.canonical_description, places.canonical_description),
      semantic_constraint = COALESCE(EXCLUDED.semantic_constraint, places.semantic_constraint),
      descriptors = COALESCE(places.descriptors, '{}'::jsonb),
      updated_at = NOW()
    RETURNING id INTO place_id_val;

    -- Update place embedding if session has description_embedding
    IF NEW.description_embedding IS NOT NULL THEN
      PERFORM update_place_embedding(place_id_val, NEW.description_embedding);
    END IF;

    -- Update session with place_id (status is calculated from was_correct)
    UPDATE game_sessions
    SET place_id = place_id_val
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."approve_pending_session" () owner TO "postgres";
