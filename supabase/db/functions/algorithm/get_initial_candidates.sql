-- Function: get_initial_candidates
-- Category: algorithm
-- Purpose: Get initial candidates by semantic similarity with configurable limits
-- Spec: openspec/specs/algorithm/spec.md#initial-candidate-scoring
CREATE OR REPLACE FUNCTION get_initial_candidates (
  p_description_embedding_id UUID,
  p_initial_threshold FLOAT DEFAULT 0.3,
  p_max_candidates INT DEFAULT 100
) returns TABLE (
  place_id UUID,
  place_name TEXT,
  lat FLOAT,
  lng FLOAT,
  raw_score FLOAT
) language plpgsql AS $$
DECLARE
  v_description_embedding vector(1024);
BEGIN
  -- Get description embedding
  SELECT embedding INTO v_description_embedding
  FROM embeddings
  WHERE id = p_description_embedding_id;
  
  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Embedding % not found', p_description_embedding_id;
  END IF;
  
  -- Get places with raw_score >= threshold, ordered by score, limited
  RETURN QUERY
  SELECT
    p.id AS place_id,
    p.name AS place_name,
    p.lat::FLOAT,
    p.lng::FLOAT,
    (1 - (e.embedding <=> v_description_embedding))::FLOAT AS raw_score
  FROM places p
  JOIN embeddings e ON e.id = p.embedding_id
  WHERE p.embedding_id IS NOT NULL
  AND (1 - (e.embedding <=> v_description_embedding)) >= p_initial_threshold
  ORDER BY raw_score DESC
  LIMIT p_max_candidates;
END;
$$;


ALTER FUNCTION get_initial_candidates (UUID, FLOAT, INT) owner TO postgres;


comment ON function get_initial_candidates (UUID, FLOAT, INT) IS 'Gets initial candidates by semantic similarity to description.

Process:
1. raw_score = similarity(place.embedding, description.embedding)
2. Filter: raw_score >= initial_candidate_threshold
3. Order by raw_score descending
4. Limit to max_initial_candidates

Uses pgvector cosine distance (<=>), converted to similarity (1 - distance).

Parameters:
- p_description_embedding_id: UUID of description embedding
- p_initial_threshold: Minimum similarity (default 0.3)
- p_max_candidates: Maximum candidates to return (default 100)';
