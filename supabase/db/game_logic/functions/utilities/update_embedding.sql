-- Function: update_embedding
-- Category: utilities
-- Updates existing embedding with new text
CREATE OR REPLACE FUNCTION "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_new_embedding vector(384);
BEGIN
  -- Generate new embedding
  v_new_embedding := generate_embedding(p_new_text);

  -- Update embedding record
  UPDATE embeddings
  SET
    source_text = p_new_text,
    embedding = v_new_embedding,
    updated_at = now()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Embedding with ID % not found', p_id;
  END IF;
END;
$$;


ALTER FUNCTION "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") owner TO "postgres";


comment ON function "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") IS 'Updates existing embedding with new text. Regenerates embedding.';
