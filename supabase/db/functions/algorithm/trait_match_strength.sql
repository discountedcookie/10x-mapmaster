-- Function: calculate_trait_match_strength
-- Category: algorithm
-- Purpose: Calculate match strength and zone for trait-place pairs
-- Spec: openspec/specs/algorithm/spec.md#trait-match-scoring
CREATE OR REPLACE FUNCTION calculate_trait_match_strength (
  p_place_embedding vector (1024),
  p_trait_embedding vector (1024),
  p_strong_threshold FLOAT DEFAULT 0.7,
  p_partial_threshold FLOAT DEFAULT 0.5
) returns TABLE (match_strength FLOAT, match_zone TEXT) language plpgsql immutable AS $$
DECLARE
  v_similarity FLOAT;
BEGIN
  -- Calculate cosine similarity (1 - cosine distance)
  v_similarity := 1 - (p_place_embedding <=> p_trait_embedding);
  
  -- Determine match zone
  RETURN QUERY SELECT 
    v_similarity,
    CASE
      WHEN v_similarity >= p_strong_threshold THEN 'STRONG'
      WHEN v_similarity >= p_partial_threshold THEN 'PARTIAL'
      ELSE 'WEAK'
    END AS match_zone;
END;
$$;


ALTER FUNCTION calculate_trait_match_strength (vector (1024), vector (1024), FLOAT, FLOAT) owner TO postgres;


comment ON function calculate_trait_match_strength (vector (1024), vector (1024), FLOAT, FLOAT) IS 'Calculates match strength between place and trait embeddings.

Match zones:
- STRONG: match_strength >= strong_threshold (default 0.7)
- PARTIAL: match_strength >= partial_threshold (default 0.5)
- WEAK: below partial_threshold

Returns:
- match_strength: cosine similarity (0-1)
- match_zone: STRONG, PARTIAL, or WEAK';
