-- Function: calculate_dynamic_threshold
-- Category: algorithm
-- Purpose: Calculate dynamic guess threshold based on turn, candidate count, and margin
-- Spec: openspec/changes/add-smart-confidence-thresholds/specs/algorithm/spec.md
CREATE OR REPLACE FUNCTION "game_logic"."calculate_dynamic_threshold" (
  p_current_turn INT,
  p_max_turns INT,
  p_candidate_count INT,
  p_margin FLOAT
) returns FLOAT language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_threshold_max FLOAT;
  v_threshold_min FLOAT;
  v_threshold_floor FLOAT;
  v_threshold_ceiling FLOAT;
  v_candidate_low_threshold INT;
  v_candidate_bonus FLOAT;
  v_margin_high_threshold FLOAT;
  v_margin_bonus FLOAT;
  v_base_threshold FLOAT;
  v_progress FLOAT;
  v_result FLOAT;
BEGIN
  -- Read all configuration knobs
  v_threshold_max := get_config_float('confidence.guess_threshold_max', 0.90);
  v_threshold_min := get_config_float('confidence.guess_threshold_min', 0.60);
  v_threshold_floor := get_config_float('confidence.threshold_floor', 0.50);
  v_threshold_ceiling := get_config_float('confidence.threshold_ceiling', 0.95);
  v_candidate_low_threshold := get_config_int('confidence.candidate_low_threshold', 3);
  v_candidate_bonus := get_config_float('confidence.candidate_bonus', 0.10);
  v_margin_high_threshold := get_config_float('confidence.margin_high_threshold', 0.25);
  v_margin_bonus := get_config_float('confidence.margin_bonus', 0.10);
  
  -- Calculate progress through game: 0.0 at turn 0, 1.0 at max_turns
  IF p_max_turns <= 0 THEN
    v_progress := 1.0;  -- Safety: treat invalid max_turns as final turn
  ELSE
    v_progress := LEAST(1.0, p_current_turn::FLOAT / p_max_turns::FLOAT);
  END IF;
  
  -- Linear interpolation: start with threshold_max, decrease to threshold_min
  -- base = max - (max - min) * progress
  v_base_threshold := v_threshold_max - (v_threshold_max - v_threshold_min) * v_progress;
  
  -- Apply candidate bonus if few candidates remain
  IF p_candidate_count <= v_candidate_low_threshold THEN
    v_base_threshold := v_base_threshold - v_candidate_bonus;
  END IF;
  
  -- Apply margin bonus if gap between top two is large
  IF p_margin >= v_margin_high_threshold THEN
    v_base_threshold := v_base_threshold - v_margin_bonus;
  END IF;
  
  -- Clamp between floor and ceiling
  v_result := GREATEST(v_threshold_floor, LEAST(v_threshold_ceiling, v_base_threshold));
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."calculate_dynamic_threshold" (INT, INT, INT, FLOAT) owner TO postgres;


comment ON function "game_logic"."calculate_dynamic_threshold" (INT, INT, INT, FLOAT) IS 'Calculates dynamic guess threshold based on game progress and board state.

Input parameters:
- p_current_turn: Current turn number (0-indexed)
- p_max_turns: Maximum turns in game
- p_candidate_count: Number of remaining candidates
- p_margin: Margin between top two candidates (top_prob - second_prob)

Algorithm:
1. Base threshold interpolates linearly from guess_threshold_max (turn 0) to guess_threshold_min (final turn)
2. Apply candidate_bonus if candidate_count <= candidate_low_threshold
3. Apply margin_bonus if margin >= margin_high_threshold
4. Clamp result between threshold_floor and threshold_ceiling

Configuration keys (with defaults):
- confidence.guess_threshold_max (0.90)
- confidence.guess_threshold_min (0.60)
- confidence.threshold_floor (0.50)
- confidence.threshold_ceiling (0.95)
- confidence.candidate_low_threshold (3)
- confidence.candidate_bonus (0.10)
- confidence.margin_high_threshold (0.25)
- confidence.margin_bonus (0.10)

Returns: FLOAT threshold value (clamped between floor and ceiling)';
