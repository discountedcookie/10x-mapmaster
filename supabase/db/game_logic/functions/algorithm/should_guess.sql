-- Function: should_guess
-- Category: algorithm
-- Purpose: Decide whether to guess based on dynamic threshold
-- Spec: openspec/changes/add-smart-confidence-thresholds/specs/algorithm/spec.md
CREATE OR REPLACE FUNCTION "game_logic"."should_guess" (
  p_probabilities FLOAT[],
  p_threshold FLOAT
) returns BOOLEAN language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_top_prob FLOAT;
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
  
  -- Get top probability (array is already sorted DESC by caller)
  v_top_prob := p_probabilities[1];
  
  -- Simple threshold check: guess if top probability exceeds dynamic threshold
  RETURN v_top_prob >= p_threshold;
END;
$$;


ALTER FUNCTION "game_logic"."should_guess" (FLOAT[], FLOAT) owner TO postgres;


comment ON function "game_logic"."should_guess" (FLOAT[], FLOAT) IS 'Decides whether to guess based on dynamic threshold.

Decision Rule:
- Guess if top_prob >= p_threshold

The threshold is calculated dynamically by calculate_dynamic_threshold() based on:
- Turn progress (more aggressive as game progresses)
- Candidate count (bonus if few candidates)
- Margin between top two (bonus if clear leader)

Edge cases:
- Single candidate: automatic guess (returns TRUE)
- Zero candidates: cannot guess (returns FALSE)

Returns TRUE if should guess, FALSE if should ask question.';
