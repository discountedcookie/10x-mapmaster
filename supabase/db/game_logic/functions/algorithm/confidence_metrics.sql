-- Function: calculate_confidence_metrics
-- Category: algorithm
-- Purpose: Calculate top_prob, margin, and normalized_entropy for guess decision
-- Spec: openspec/specs/algorithm/spec.md#confidence-decision-metrics
CREATE OR REPLACE FUNCTION "game_logic"."calculate_confidence_metrics" (p_probabilities FLOAT[]) returns TABLE (
  top_prob FLOAT,
  margin FLOAT,
  normalized_entropy FLOAT
) language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_top_prob FLOAT := 0;
  v_second_prob FLOAT := 0;
  v_entropy FLOAT := 0;
  v_count INT;
  v_prob FLOAT;
  i INT;
BEGIN
  v_count := COALESCE(array_length(p_probabilities, 1), 0);
  
  -- Edge cases
  IF v_count = 0 THEN
    RETURN QUERY SELECT 0::FLOAT, 0::FLOAT, 1::FLOAT;
    RETURN;
  END IF;
  
  IF v_count = 1 THEN
    RETURN QUERY SELECT 1::FLOAT, 1::FLOAT, 0::FLOAT;
    RETURN;
  END IF;
  
  -- Find top two probabilities and calculate entropy
  FOR i IN 1..v_count LOOP
    v_prob := p_probabilities[i];
    
    -- Track top two
    IF v_prob > v_top_prob THEN
      v_second_prob := v_top_prob;
      v_top_prob := v_prob;
    ELSIF v_prob > v_second_prob THEN
      v_second_prob := v_prob;
    END IF;
    
    -- Calculate entropy: -sum(P(i) * ln(P(i)))
    IF v_prob > 0 THEN
      v_entropy := v_entropy - (v_prob * ln(v_prob));
    END IF;
  END LOOP;
  
  -- Return metrics
  RETURN QUERY SELECT 
    v_top_prob,
    v_top_prob - v_second_prob AS margin,
    -- Normalized entropy: entropy / ln(candidate_count)
    CASE 
      WHEN v_count > 1 THEN v_entropy / ln(v_count::FLOAT)
      ELSE 0
    END AS normalized_entropy;
END;
$$;


ALTER FUNCTION "game_logic"."calculate_confidence_metrics" (FLOAT[]) owner TO postgres;


comment ON function "game_logic"."calculate_confidence_metrics" (FLOAT[]) IS 'Calculates confidence metrics for guess decision.

Returns:
- top_prob: max(P(place_i)) - highest probability
- margin: P(top) - P(second) - gap between top two
- normalized_entropy: entropy / ln(candidate_count)
  - 0 = certain (one candidate dominates)
  - 1 = maximum uncertainty (uniform distribution)

Used by should_guess() to determine if confidence thresholds are met.';
