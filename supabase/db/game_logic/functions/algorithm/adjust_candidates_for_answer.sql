-- Function: adjust_candidates_for_answer
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Adjust all candidate scores based on a semantic answer using binary trait matching
-- Spec: docs/architecture/algorithm.md#trait-matching
CREATE OR REPLACE FUNCTION "game_logic"."adjust_candidates_for_answer" (
  p_candidates JSONB,
  p_trait_id TEXT,
  p_answer answer_value
) returns JSONB language plpgsql
SET
  search_path = public, extensions, game_logic AS $$
DECLARE
  v_candidate JSONB;
  v_place_id UUID;
  v_current_score FLOAT;
  v_new_score FLOAT;
  v_has_trait BOOLEAN;
  v_boost_factor FLOAT;
  v_penalty_factor FLOAT;
  v_multiplier FLOAT;
  v_result JSONB := '[]'::JSONB;
BEGIN
  -- Not sure = return unchanged candidates
  IF p_answer = 'not_sure' THEN
    RETURN p_candidates;
  END IF;
  
  -- Get config values
  v_boost_factor := get_config_float('traits.boost_factor', 1.5);
  v_penalty_factor := get_config_float('traits.penalty_factor', 0.6);
  
  -- Process each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_place_id := (v_candidate->>'id')::UUID;
    v_current_score := COALESCE((v_candidate->>'confidence')::FLOAT, 0.5);
    
    -- Check if place has this trait (binary lookup via place_traits)
    SELECT EXISTS(
      SELECT 1 FROM place_traits 
      WHERE place_id = v_place_id AND trait_id = p_trait_id
    ) INTO v_has_trait;
    
    -- Determine multiplier based on answer and trait ownership
    -- YES + has_trait = boost (candidate matches affirmed trait)
    -- YES + !has_trait = penalty (candidate lacks affirmed trait)
    -- NO + has_trait = penalty (candidate has denied trait)
    -- NO + !has_trait = boost (candidate correctly lacks denied trait)
    IF p_answer = 'yes' THEN
      IF v_has_trait THEN
        v_multiplier := v_boost_factor;
      ELSE
        v_multiplier := v_penalty_factor;
      END IF;
    ELSE  -- p_answer = 'no'
      IF v_has_trait THEN
        v_multiplier := v_penalty_factor;
      ELSE
        v_multiplier := v_boost_factor;
      END IF;
    END IF;
    
    -- Apply multiplicative adjustment
    v_new_score := v_current_score * v_multiplier;
    
    -- Clamp score to valid range [0.01, 1.0]
    v_new_score := GREATEST(0.01, LEAST(1.0, v_new_score));
    
    -- Update candidate with new score
    v_result := v_result || jsonb_build_array(
      v_candidate || jsonb_build_object('confidence', v_new_score)
    );
  END LOOP;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."adjust_candidates_for_answer" (JSONB, TEXT, answer_value) owner TO postgres;


comment ON function "game_logic"."adjust_candidates_for_answer" (JSONB, TEXT, answer_value) IS 'Adjusts candidate scores using binary trait matching and multiplicative scaling.

Algorithm (per docs/architecture/algorithm.md#trait-matching):
1. For each candidate, check if place has the trait via place_traits table (binary)
2. Apply multiplier based on answer and trait ownership:
   - YES + has_trait → boost_factor (1.5)
   - YES + !has_trait → penalty_factor (0.6)  
   - NO + has_trait → penalty_factor (0.6)
   - NO + !has_trait → boost_factor (1.5)
3. new_score = old_score × multiplier

Why binary matching instead of embedding similarity?
- We have explicit place_traits relationships (ground truth)
- No fuzzy matching needed - place either has trait or not
- Faster and more accurate than embedding comparison

Parameters:
- p_candidates: JSONB array of candidates with confidence scores
- p_trait_id: The trait being asked about
- p_answer: yes, no, or not_sure (not_sure returns unchanged)

Returns: Updated JSONB array with adjusted confidence scores';
