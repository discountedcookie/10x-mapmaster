-- Function: update_place_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION DEFAULT 0.3
) returns "void" language "plpgsql" security definer AS $$
DECLARE
  current_embedding vector(768);
  current_count int;
  weight float;
BEGIN
  SELECT embedding, times_encountered INTO current_embedding, current_count
  FROM places
  WHERE id = place_id_param;

  IF current_embedding IS NULL THEN
    UPDATE places
    SET
      embedding = new_embedding,
      times_encountered = times_encountered + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  weight := learning_rate / (1.0 + current_count * 0.1);

  UPDATE places
  SET
    embedding = (
      SELECT array_agg(
        (1.0 - weight) * old_val + weight * new_val
      )::vector(768)
      FROM unnest(current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val)
    ),
    times_encountered = times_encountered + 1
  WHERE id = place_id_param;
END;
$$;


ALTER FUNCTION "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION
) owner TO "postgres";


comment ON function "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION
) IS 'Enhanced for v2: uses times_encountered instead of game_count.
Updates a place''s embedding using weighted average. Weight decreases as times_encountered increases.
Uses 768-dimensional vectors for nomic-embed-text model.
After update, bumps times_encountered counter.';
