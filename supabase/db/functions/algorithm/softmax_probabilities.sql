-- Function: softmax_probabilities
-- Category: algorithm
-- Purpose: Convert raw scores to probability distribution via softmax with temperature
-- Spec: openspec/specs/algorithm/spec.md#probability-distribution
CREATE OR REPLACE FUNCTION softmax_probabilities (p_scores FLOAT[], p_temperature FLOAT DEFAULT 1.0) returns FLOAT[] language plpgsql immutable AS $$
DECLARE
  v_max_score FLOAT;
  v_exp_scores FLOAT[];
  v_sum_exp FLOAT := 0;
  v_probabilities FLOAT[];
  i INT;
BEGIN
  -- Handle edge cases
  IF p_scores IS NULL OR array_length(p_scores, 1) IS NULL THEN
    RETURN ARRAY[]::FLOAT[];
  END IF;
  
  IF array_length(p_scores, 1) = 1 THEN
    RETURN ARRAY[1.0]::FLOAT[];
  END IF;
  
  -- Prevent division by zero
  IF p_temperature <= 0 THEN
    p_temperature := 0.001;
  END IF;
  
  -- Find max score for numerical stability (subtract max before exp)
  v_max_score := p_scores[1];
  FOR i IN 2..array_length(p_scores, 1) LOOP
    IF p_scores[i] > v_max_score THEN
      v_max_score := p_scores[i];
    END IF;
  END LOOP;
  
  -- Calculate exp(score_i / temperature) for each score
  v_exp_scores := ARRAY[]::FLOAT[];
  FOR i IN 1..array_length(p_scores, 1) LOOP
    v_exp_scores := array_append(v_exp_scores, exp((p_scores[i] - v_max_score) / p_temperature));
    v_sum_exp := v_sum_exp + v_exp_scores[i];
  END LOOP;
  
  -- Calculate probabilities: P(i) = exp(score_i/T) / sum(exp(score_j/T))
  v_probabilities := ARRAY[]::FLOAT[];
  FOR i IN 1..array_length(v_exp_scores, 1) LOOP
    v_probabilities := array_append(v_probabilities, v_exp_scores[i] / v_sum_exp);
  END LOOP;
  
  RETURN v_probabilities;
END;
$$;


ALTER FUNCTION softmax_probabilities (FLOAT[], FLOAT) owner TO postgres;


comment ON function softmax_probabilities (FLOAT[], FLOAT) IS 'Converts raw scores to probability distribution via softmax.

Formula: P(place_i) = exp(score_i / temperature) / sum(exp(score_j / temperature))

Parameters:
- p_scores: Array of raw similarity scores
- p_temperature: Temperature parameter (default 1.0)
  - Lower temperature = sharper distribution (amplifies differences)
  - Higher temperature = flatter distribution

Returns: Array of probabilities that sum to 1.0

Uses numerical stability trick: subtracts max score before exp to prevent overflow.';
