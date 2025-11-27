-- Function: filter_semantic_candidates
-- Category: game
-- Purpose: Calculate semantic similarity scores for specific place IDs
-- Returns: Place IDs with similarity scores
CREATE OR REPLACE FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) returns TABLE (
  place_id UUID,
  base_description_similarity DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_description_embedding vector(384);
  v_semantic_threshold FLOAT;
BEGIN
  -- Get semantic similarity threshold from game_logic.config
  v_semantic_threshold := get_config_float('candidates.semantic_similarity_threshold', 0.5);

  -- Get session embedding
  SELECT
    de_desc.embedding as description_embedding
  INTO
    v_description_embedding
  FROM game_sessions gs
  LEFT JOIN embeddings de_desc ON de_desc.id = gs.embedding_id
  WHERE gs.id = p_session_id;

  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', p_session_id;
  END IF;

  -- Calculate semantic similarity scores for given place IDs
  RETURN QUERY
  SELECT
    p.id AS place_id,
    (1 - (e.embedding <=> v_description_embedding))::DOUBLE PRECISION AS base_description_similarity
  FROM
    places p
    JOIN embeddings e ON e.id = p.embedding_id
  WHERE
    p.id = ANY (p_place_ids)
    -- Only return candidates above base similarity threshold
    AND (1 - (e.embedding <=> v_description_embedding)) > v_semantic_threshold;
END;
$$;


ALTER FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) owner TO "postgres";


comment ON function "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) IS 'Calculates semantic similarity scores for specific place IDs (SRP: Semantics only).

Input:
- p_session_id: Session to get embeddings from
- p_place_ids: Array of place IDs to score (from geographic filter)

Calculates:
- base_description_similarity: Cosine similarity with session description

Threshold: Only returns places with base_description_similarity > 0.5

Returns: Only similarity scores (no geographic data, no composite scoring).

Called by: get_candidates() which joins with geographic results.';
