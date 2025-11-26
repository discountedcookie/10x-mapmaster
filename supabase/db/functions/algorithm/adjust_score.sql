-- Function: adjust_score
-- Category: algorithm
-- Purpose: Adjust candidate score based on answer using power-law scaling
-- Spec: openspec/specs/algorithm/spec.md#score-adjustment
CREATE OR REPLACE FUNCTION adjust_score (
  p_current_score FLOAT,
  p_match_strength FLOAT,
  p_match_zone TEXT,
  p_answer TEXT, -- 'yes', 'no', 'not_sure'
  p_base_weight FLOAT DEFAULT 0.3,
  p_beta FLOAT DEFAULT 1.5
) returns FLOAT language plpgsql immutable AS $$
DECLARE
  v_magnitude FLOAT;
  v_adjustment FLOAT;
BEGIN
  -- Not sure = no adjustment
  IF p_answer = 'not_sure' THEN
    RETURN p_current_score;
  END IF;
  
  -- Calculate adjustment magnitude with power-law scaling
  -- magnitude = base_weight * match_strength^beta
  v_magnitude := p_base_weight * power(p_match_strength, p_beta);
  
  -- Determine adjustment direction based on answer and match zone
  IF p_answer = 'yes' THEN
    IF p_match_zone IN ('STRONG', 'PARTIAL') THEN
      -- YES + strong/partial match = boost (place has affirmed trait)
      v_adjustment := v_magnitude;
    ELSE
      -- YES + weak match = penalty (place lacks affirmed trait)
      v_adjustment := -v_magnitude;
    END IF;
  ELSIF p_answer = 'no' THEN
    IF p_match_zone IN ('STRONG', 'PARTIAL') THEN
      -- NO + strong/partial match = penalty (place has denied trait)
      v_adjustment := -v_magnitude;
    ELSE
      -- NO + weak match = boost (place correctly lacks denied trait)
      v_adjustment := v_magnitude * 0.5;  -- Smaller boost for "doesn't have"
    END IF;
  ELSE
    v_adjustment := 0;
  END IF;
  
  RETURN p_current_score + v_adjustment;
END;
$$;


ALTER FUNCTION adjust_score (FLOAT, FLOAT, TEXT, TEXT, FLOAT, FLOAT) owner TO postgres;


comment ON function adjust_score (FLOAT, FLOAT, TEXT, TEXT, FLOAT, FLOAT) IS 'Adjusts candidate score based on answer using power-law scaling.

Formula: magnitude = base_weight * match_strength^beta

Adjustment rules:
- YES + STRONG/PARTIAL match: positive (boost - place has affirmed trait)
- YES + WEAK match: negative (penalty - place lacks affirmed trait)
- NO + STRONG/PARTIAL match: negative (penalty - place has denied trait)
- NO + WEAK match: positive (boost - place correctly lacks denied trait)
- NOT SURE: no adjustment

Parameters:
- p_base_weight: Base weight for adjustments (default 0.3)
- p_beta: Power-law exponent (default 1.5)';
