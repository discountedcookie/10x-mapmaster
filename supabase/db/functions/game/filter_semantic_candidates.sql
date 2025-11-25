-- Function: filter_semantic_candidates
-- Category: game
-- Purpose: Calculate semantic similarity scores for specific place IDs
-- Returns: Place IDs with similarity scores
CREATE OR REPLACE FUNCTION "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) returns TABLE (
  place_id UUID,
  base_description_similarity DOUBLE PRECISION,
  affirmed_trait_similarity DOUBLE PRECISION,
  denied_trait_similarity DOUBLE PRECISION
) language "plpgsql" AS $$
DECLARE
  v_description_embedding vector(1024);
  v_affirmed_embedding vector(1024);
  v_denied_embedding vector(1024);
  v_semantic_threshold FLOAT;
BEGIN
  -- Get semantic similarity threshold from settings
  SELECT value::FLOAT INTO v_semantic_threshold
  FROM app_settings 
  WHERE key = 'semantic_similarity_threshold';
  
  IF v_semantic_threshold IS NULL THEN
    RAISE EXCEPTION 'Missing required app_setting: semantic_similarity_threshold';
  END IF;

  -- Get session embeddings
  SELECT
    de_desc.embedding as description_embedding,
    de_affirmed.embedding as affirmed_embedding,
    de_denied.embedding as denied_embedding
  INTO
    v_description_embedding,
    v_affirmed_embedding,
    v_denied_embedding
  FROM game_sessions gs
  LEFT JOIN embeddings de_desc ON de_desc.id = gs.description_embedding_id
  LEFT JOIN embeddings de_affirmed ON de_affirmed.id = gs.affirmed_trait_embedding_id
  LEFT JOIN embeddings de_denied ON de_denied.id = gs.denied_trait_embedding_id
  WHERE gs.id = p_session_id;

  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', p_session_id;
  END IF;

  -- Calculate semantic similarity scores for given place IDs
  RETURN QUERY
  SELECT
    p.id AS place_id,
    (1 - (e.embedding <=> v_description_embedding))::DOUBLE PRECISION AS base_description_similarity,
    CASE
      WHEN v_affirmed_embedding IS NOT NULL
      THEN (1 - (e.embedding <=> v_affirmed_embedding))::DOUBLE PRECISION
      ELSE NULL
    END AS affirmed_trait_similarity,
    CASE
      WHEN v_denied_embedding IS NOT NULL
      THEN (1 - (e.embedding <=> v_denied_embedding))::DOUBLE PRECISION
      ELSE NULL
    END AS denied_trait_similarity
  FROM
    places p
    JOIN embeddings e ON e.id = p.embedding_id
  WHERE
    p.id = ANY (p_place_ids)
    -- Only return candidates above base similarity threshold
    AND (1 - (e.embedding <=> v_description_embedding)) > v_semantic_threshold;
END;
$$;


ALTER FUNCTION "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) owner TO "postgres";


comment ON function "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) IS 'Calculates semantic similarity scores for specific place IDs (SRP: Semantics only).

Input:
- p_session_id: Session to get embeddings from
- p_place_ids: Array of place IDs to score (from geographic filter)

Calculates:
- base_description_similarity: Cosine similarity with session description
- affirmed_trait_similarity: Cosine similarity with affirmed traits (if any)
- denied_trait_similarity: Cosine similarity with denied traits (if any)

Threshold: Only returns places with base_description_similarity > 0.5

Returns: Only similarity scores (no geographic data, no composite scoring).

Called by: get_candidates() which joins with geographic results.';
