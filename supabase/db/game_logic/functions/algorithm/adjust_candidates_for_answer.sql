-- Function: adjust_candidates_for_answer
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Adjust all candidate scores based on a semantic answer
-- Spec: spec/algorithm.md#score-adjustment
CREATE OR REPLACE FUNCTION "game_logic"."adjust_candidates_for_answer" (
  p_candidates JSONB,
  p_trait_id TEXT,
  p_answer answer_value,
  p_base_weight FLOAT DEFAULT 0.3,
  p_beta FLOAT DEFAULT 1.5
) returns JSONB language plpgsql
SET
  search_path = public, extensions, game_logic AS $$
DECLARE
  v_candidate JSONB;
  v_place_id UUID;
  v_current_score FLOAT;
  v_new_score FLOAT;
  v_match_strength FLOAT;
  v_match_zone TEXT;
  v_result JSONB := '[]'::JSONB;
BEGIN
  -- Not sure = return unchanged candidates
  IF p_answer = 'not_sure' THEN
    RETURN p_candidates;
  END IF;
  
  -- Process each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_place_id := (v_candidate->>'id')::UUID;
    v_current_score := COALESCE((v_candidate->>'confidence')::FLOAT, 0.5);
    
    -- Calculate embedding similarity between place and trait
    DECLARE
      v_place_embedding vector(384);
      v_trait_embedding vector(384);
      v_similarity FLOAT;
      v_similarity_threshold FLOAT;
    BEGIN
      -- Get embeddings
      SELECT pe.embedding INTO v_place_embedding
      FROM places p
      JOIN embeddings pe ON pe.id = p.embedding_id
      WHERE p.id = v_place_id;
      
      SELECT te.embedding INTO v_trait_embedding
      FROM traits t
      JOIN embeddings te ON te.id = t.embedding_id
      WHERE t.id = p_trait_id;
      
      -- Calculate cosine similarity
      v_similarity := 1 - (v_place_embedding <=> v_trait_embedding);
      
      -- Get similarity threshold from config
      v_similarity_threshold := get_config_float('traits.similarity_threshold');
      
      -- Determine match strength based on similarity
      IF v_similarity >= v_similarity_threshold THEN
        v_match_strength := v_similarity;  -- Use actual similarity as strength
        v_match_zone := 'STRONG';
      ELSE
        v_match_strength := v_similarity;  -- Use actual similarity as strength
        v_match_zone := 'WEAK';
      END IF;
    END;
    
    -- Calculate new score using adjust_score
    v_new_score := adjust_score(
      v_current_score,
      v_match_strength,
      v_match_zone,
      p_answer::TEXT,
      p_base_weight,
      p_beta
    );
    
    -- Update candidate with new score
    v_result := v_result || jsonb_build_array(
      v_candidate || jsonb_build_object('confidence', v_new_score)
    );
  END LOOP;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."adjust_candidates_for_answer" (JSONB, TEXT, answer_value, FLOAT, FLOAT) owner TO postgres;


comment ON function "game_logic"."adjust_candidates_for_answer" (JSONB, TEXT, answer_value, FLOAT, FLOAT) IS 'Adjusts all candidate scores based on a semantic answer.

Per spec (algorithm.md#score-adjustment):
- For each candidate, calculate match_strength against trait
- Apply power-law adjustment: magnitude = base_weight * match_strength^beta
- Adjustment direction based on answer + match zone

Match strength determination:
- Uses embedding similarity between place and trait
- Similarity >= threshold → STRONG match
- Similarity < threshold → WEAK match
- Uses actual similarity value as match_strength (0.0-1.0)

Parameters:
- p_candidates: JSONB array of candidates with confidence scores
- p_trait_id: The trait being asked about
- p_answer: yes, no, or not_sure (not_sure returns unchanged)
- p_base_weight: Base weight for adjustments (default 0.3)
- p_beta: Power-law exponent (default 1.5)

Returns: Updated JSONB array with adjusted confidence scores';
