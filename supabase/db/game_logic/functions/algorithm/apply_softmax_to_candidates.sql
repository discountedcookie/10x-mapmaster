-- Function: apply_softmax_to_candidates
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Apply softmax to convert candidate scores to probabilities
-- Spec: spec/algorithm.md#probability-distribution
CREATE OR REPLACE FUNCTION "game_logic"."apply_softmax_to_candidates" (
  p_candidates JSONB,
  p_temperature FLOAT DEFAULT 1.0
) returns JSONB language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_scores FLOAT[];
  v_probabilities FLOAT[];
  v_candidate JSONB;
  v_result JSONB := '[]'::JSONB;
  v_idx INT := 1;
BEGIN
  -- Handle empty candidates
  IF p_candidates IS NULL OR jsonb_array_length(p_candidates) = 0 THEN
    RETURN '[]'::JSONB;
  END IF;
  
  -- Extract scores from candidates
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_scores := array_append(v_scores, COALESCE((v_candidate->>'confidence')::FLOAT, 0.5));
  END LOOP;
  
  -- Calculate probabilities via softmax
  v_probabilities := softmax_probabilities(v_scores, p_temperature);
  
  -- Update candidates with probabilities and re-sort by probability DESC
  v_idx := 1;
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_result := v_result || jsonb_build_array(
      v_candidate || jsonb_build_object('probability', v_probabilities[v_idx])
    );
    v_idx := v_idx + 1;
  END LOOP;
  
  -- Sort by probability descending
  SELECT jsonb_agg(c ORDER BY (c->>'probability')::FLOAT DESC)
  INTO v_result
  FROM jsonb_array_elements(v_result) c;
  
  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;


ALTER FUNCTION "game_logic"."apply_softmax_to_candidates" (JSONB, FLOAT) owner TO postgres;


comment ON function "game_logic"."apply_softmax_to_candidates" (JSONB, FLOAT) IS 'Applies softmax to convert candidate confidence scores to probabilities.

Per spec (algorithm.md#probability-distribution):
P(place_i) = exp(score_i / temperature) / sum(exp(score_j / temperature))

After adjustments, recalculate probability distribution via softmax.

Parameters:
- p_candidates: JSONB array of candidates with confidence scores
- p_temperature: Softmax temperature (default 1.0)

Returns: JSONB array with added "probability" field, sorted by probability DESC';
