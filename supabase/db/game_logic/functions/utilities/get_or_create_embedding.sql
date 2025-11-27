-- Function: get_or_create_embedding
-- Category: utilities
-- Gets existing embedding or creates a new one for the given text
CREATE OR REPLACE FUNCTION "game_logic"."get_or_create_embedding" ("p_text" "text") returns UUID language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_embedding_id uuid;
  v_embedding vector(384);
BEGIN
  -- First, check if embedding already exists
  SELECT id INTO v_embedding_id
  FROM embeddings
  WHERE source_text = p_text;
  
  -- If found, return existing ID
  IF v_embedding_id IS NOT NULL THEN
    RETURN v_embedding_id;
  END IF;

  -- Generate new embedding
  v_embedding := generate_embedding(p_text);

  -- Store new embedding (use ON CONFLICT for race condition safety)
  INSERT INTO embeddings (source_text, embedding)
  VALUES (p_text, v_embedding)
  ON CONFLICT (source_text) DO UPDATE SET source_text = EXCLUDED.source_text
  RETURNING id INTO v_embedding_id;

  RETURN v_embedding_id;
END;
$$;


ALTER FUNCTION "game_logic"."get_or_create_embedding" ("p_text" "text") owner TO "postgres";


comment ON function "game_logic"."get_or_create_embedding" ("p_text" "text") IS 'Creates a new embedding for the given text.

Process:
1. Call edge function to generate embedding
2. Store new embedding in database
3. Return new ID

Returns: embedding UUID';
