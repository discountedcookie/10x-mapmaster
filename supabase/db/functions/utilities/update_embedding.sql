-- Function: update_embedding
-- Category: utilities
-- Updates existing embedding with new text
CREATE OR REPLACE FUNCTION "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") returns void language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_new_embedding vector(1024);
  v_new_text_hash text;
BEGIN
  -- Generate SHA256 hash of new text
  v_new_text_hash := encode(digest(p_new_text, 'sha256'), 'hex');

  -- Generate new embedding
  v_new_embedding := generate_embedding(p_new_text);

  -- Update embedding record
  UPDATE embeddings
  SET
    text = p_new_text,
    text_hash = v_new_text_hash,
    embedding = v_new_embedding,
    updated_at = now()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Embedding with ID % not found', p_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") owner TO "postgres";


comment ON function "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") IS 'Updates existing embedding with new text. Regenerates embedding and updates hash.';
