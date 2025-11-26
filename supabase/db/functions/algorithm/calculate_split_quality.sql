-- Function: calculate_split_quality
-- Category: algorithm
-- Purpose: Calculate how evenly a question splits candidates
-- Spec: openspec/specs/algorithm/spec.md#question-split-quality
CREATE OR REPLACE FUNCTION calculate_split_quality (p_matching_count INT, p_total_count INT) returns FLOAT language plpgsql immutable AS $$
DECLARE
  v_fraction FLOAT;
BEGIN
  -- Edge cases
  IF p_total_count <= 0 THEN
    RETURN 0;
  END IF;
  
  IF p_total_count = 1 THEN
    RETURN 0;  -- Can't split a single candidate
  END IF;
  
  -- Calculate fraction matching
  v_fraction := p_matching_count::FLOAT / p_total_count::FLOAT;
  
  -- Split quality = 1 - |0.5 - fraction|
  -- 0.5 fraction = 1.0 quality (perfect split)
  -- 0.0 or 1.0 fraction = 0.5 quality (useless question)
  RETURN 1 - abs(0.5 - v_fraction);
END;
$$;


ALTER FUNCTION calculate_split_quality (INT, INT) owner TO postgres;


comment ON function calculate_split_quality (INT, INT) IS 'Calculates how evenly a question splits candidates.

Formula: split_quality = 1 - |0.5 - fraction|
Where: fraction = matching_count / total_count

Quality interpretation:
- 1.0: Perfect split (50% match)
- 0.75: Good split (25% or 75% match)
- 0.5: Useless question (0% or 100% match)

Returns value between 0.5 and 1.0.';
