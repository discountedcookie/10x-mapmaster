-- Function: get_or_create_embedding
-- Category: utilities
-- Gets existing embedding ID or creates new one if not found
CREATE OR REPLACE FUNCTION "public"."get_or_create_embedding" ("p_text" "text") returns UUID language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_text_hash text;
  v_embedding_id uuid;
  v_embedding vector(1024);
BEGIN
  -- Generate SHA256 hash of text
  v_text_hash := encode(extensions.digest(p_text, 'sha256'), 'hex');

  -- Try to find existing embedding by hash
  SELECT id INTO v_embedding_id
  FROM embeddings
  WHERE text_hash = v_text_hash;

  -- If found, return existing ID
  IF v_embedding_id IS NOT NULL THEN
    RETURN v_embedding_id;
  END IF;

  -- If not found, generate and store new embedding
  v_embedding := generate_embedding(p_text);

  INSERT INTO embeddings (text, text_hash, embedding)
  VALUES (p_text, v_text_hash, v_embedding)
  RETURNING id INTO v_embedding_id;

  RETURN v_embedding_id;
END;
$$;


ALTER FUNCTION "public"."get_or_create_embedding" ("p_text" "text") owner TO "postgres";


comment ON function "public"."get_or_create_embedding" ("p_text" "text") IS 'Gets existing embedding ID by text hash, or generates and stores new one if not found.

Process:
1. Hash the input text (SHA256)
2. Look up existing embedding by hash
3. If found, return existing ID (cached)
4. If not found, call edge function to generate embedding
5. Store new embedding in database
6. Return new ID

Returns: embedding UUID';
