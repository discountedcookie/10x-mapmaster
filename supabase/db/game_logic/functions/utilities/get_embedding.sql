-- Function: get_embedding
-- Category: utilities
-- Gets existing embedding or creates a new one for the given text
CREATE OR REPLACE FUNCTION "game_logic"."get_embedding" (
  "p_text" "text",
  "p_input_type" "text" DEFAULT 'query'  -- 'query' for searches, 'passage' for documents/traits
) returns UUID language "plpgsql" security definer
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

  -- Generate new embedding with the specified input type
  v_embedding := generate_embedding(p_text, p_input_type);

  -- Store new embedding (use ON CONFLICT for race condition safety)
  INSERT INTO embeddings (source_text, embedding)
  VALUES (p_text, v_embedding)
  ON CONFLICT (source_text) DO UPDATE SET source_text = EXCLUDED.source_text
  RETURNING id INTO v_embedding_id;

  RETURN v_embedding_id;
END;
$$;


ALTER FUNCTION "game_logic"."get_embedding" ("p_text" "text", "p_input_type" "text") owner TO "postgres";


comment ON function "game_logic"."get_embedding" ("p_text" "text", "p_input_type" "text") IS 'Gets existing embedding for the given text or creates a new one.

Parameters:
- p_text: text to embed
- p_input_type: ''query'' for user searches, ''passage'' for documents/traits (default: ''query'')

Process:
1. Return existing embedding_id when source_text matches
2. Otherwise call generate_embedding with appropriate input_type
3. Return embedding UUID

Note: The input_type affects the E5 model prefix used during embedding generation.
Cached embeddings are keyed by source_text only, so ensure consistent input_type usage per text.';
