-- Function: should_guess
-- Category: algorithm
-- Purpose: Decide whether to guess based on confidence thresholds
-- Spec: openspec/specs/algorithm/spec.md#guess-decision-rule
CREATE OR REPLACE FUNCTION should_guess (
  p_probabilities FLOAT[],
  p_top_prob_threshold FLOAT DEFAULT 0.4,
  p_margin_threshold FLOAT DEFAULT 0.15,
  p_entropy_threshold FLOAT DEFAULT 0.7
) returns BOOLEAN language plpgsql immutable AS $$
DECLARE
  v_metrics RECORD;
  v_count INT;
BEGIN
  v_count := COALESCE(array_length(p_probabilities, 1), 0);
  
  -- Edge case: single candidate = automatic guess
  IF v_count = 1 THEN
    RETURN TRUE;
  END IF;
  
  -- Edge case: no candidates = cannot guess
  IF v_count = 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Get confidence metrics
  SELECT * INTO v_metrics FROM calculate_confidence_metrics(p_probabilities);
  
  -- All three thresholds must pass
  -- top_prob >= threshold AND margin >= threshold AND entropy <= threshold
  RETURN (
    v_metrics.top_prob >= p_top_prob_threshold
    AND v_metrics.margin >= p_margin_threshold
    AND v_metrics.normalized_entropy <= p_entropy_threshold
  );
END;
$$;


ALTER FUNCTION should_guess (FLOAT[], FLOAT, FLOAT, FLOAT) owner TO postgres;


comment ON function should_guess (FLOAT[], FLOAT, FLOAT, FLOAT) IS 'Decides whether to guess based on confidence thresholds.

Decision Rule (ALL must pass):
- top_prob >= threshold (default 0.4)
- margin >= threshold (default 0.15)  
- normalized_entropy <= threshold (default 0.7)

Edge cases:
- Single candidate: automatic guess (returns TRUE)
- Zero candidates: cannot guess (returns FALSE)
- All scores identical: all thresholds fail, ask question

Returns TRUE if should guess, FALSE if should ask question.';
