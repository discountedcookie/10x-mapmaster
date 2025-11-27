-- Function: update_place_embedding
-- Category: utilities
-- Purpose: Update place embedding using weighted average (learning)
-- Uses embedding_id FK to embeddings table (not direct embedding column)
CREATE OR REPLACE FUNCTION "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION DEFAULT 0.3
) returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_embedding_id uuid;
  v_current_embedding vector(384);
  v_current_count int;
  v_weight float;
  v_blended_embedding vector(384);
BEGIN
  -- Get current embedding_id and times_encountered from places
  SELECT p.embedding_id, p.times_encountered 
  INTO v_embedding_id, v_current_count
  FROM places p
  WHERE p.id = place_id_param;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', place_id_param;
  END IF;

  -- If place has no embedding yet, create one
  IF v_embedding_id IS NULL THEN
    INSERT INTO embeddings (embedding)
    VALUES (new_embedding)
    RETURNING id INTO v_embedding_id;
    
    UPDATE places
    SET
      embedding_id = v_embedding_id,
      times_encountered = times_encountered + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  -- Get current embedding from embeddings table
  SELECT e.embedding INTO v_current_embedding
  FROM embeddings e
  WHERE e.id = v_embedding_id;

  -- Calculate weight (decreases as times_encountered increases)
  v_weight := learning_rate / (1.0 + v_current_count * 0.1);

  -- Blend embeddings using weighted average
  SELECT array_agg(
    (1.0 - v_weight) * old_val + v_weight * new_val
  )::vector(384)
  INTO v_blended_embedding
  FROM unnest(v_current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val);

  -- Update embedding in embeddings table
  UPDATE embeddings
  SET
    embedding = v_blended_embedding,
    updated_at = now()
  WHERE id = v_embedding_id;

  -- Bump times_encountered on place
  UPDATE places
  SET times_encountered = times_encountered + 1
  WHERE id = place_id_param;
END;
$$;


ALTER FUNCTION "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION
) owner TO "postgres";


comment ON function "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION
) IS 'Updates a place''s embedding using weighted average (learning).
Weight decreases as times_encountered increases.
Uses 384-dimensional vectors (gte-small compatible per spec).
Updates embedding via embedding_id FK to embeddings table.
After update, bumps times_encountered counter.';
