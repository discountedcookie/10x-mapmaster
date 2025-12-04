-- Function: decide_next_turn
-- Category: game
-- Purpose: Decide whether to guess or ask a question based on current candidates
-- Builds complete next_turn JSONB with action and candidates
-- Updated to use new algorithm functions for probability-based decision making
CREATE OR REPLACE FUNCTION "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) returns void language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_candidates JSONB;
  v_candidate_count INT;
  v_confidence_scores FLOAT[];
  v_probabilities FLOAT[];
  v_confidence_metrics RECORD;
  v_dynamic_threshold FLOAT;
  v_should_guess BOOLEAN;
  v_top_candidate JSONB;
  v_question_record RECORD;
  v_next_turn JSONB;
  v_total_turns INT;
  v_max_turns INT;
  v_softmax_temperature FLOAT;
BEGIN
  -- Get configuration from game_logic.config (NO FALLBACKS - fail visibly if missing)
  v_max_turns := get_max_turns();
  v_softmax_temperature := get_config_float('scoring.temperature');

  -- Get current turn count
  SELECT COUNT(*) INTO v_total_turns
  FROM game_answers ga
  WHERE ga.session_id = p_session_id;

  -- Use provided candidates
  v_candidates := p_candidates;
  v_candidate_count := jsonb_array_length(p_candidates);

  -- Check if game over (exceeded max_turns)
  IF v_total_turns > v_max_turns THEN
    UPDATE game_sessions
    SET next_turn = NULL, was_correct = FALSE
    WHERE id = p_session_id;
    
    RETURN;
  END IF;

  -- Zero candidates: give up
  IF v_candidate_count = 0 THEN
    UPDATE game_sessions
    SET next_turn = jsonb_build_object(
      'action', 'give_up',
      'reason', 'no_candidates'
    )
    WHERE id = p_session_id;
    
    RETURN;
  END IF;

  -- Extract confidence scores from candidates and convert to probabilities
  SELECT ARRAY_AGG((elem->>'confidence')::FLOAT ORDER BY (elem->>'confidence')::FLOAT DESC)
  INTO v_confidence_scores
  FROM jsonb_array_elements(v_candidates) elem;
  
  -- Convert scores to probability distribution using softmax
  v_probabilities := softmax_probabilities(v_confidence_scores, v_softmax_temperature);
  
  -- Apply softmax probabilities to candidates JSONB (adds 'probability' field)
  v_candidates := apply_softmax_to_candidates(v_candidates, v_softmax_temperature);
  
  -- Calculate confidence metrics (top_prob, margin, normalized_entropy)
  -- Note: Select specific columns to avoid TupleDesc resource leak
  SELECT top_prob, margin, normalized_entropy INTO v_confidence_metrics
  FROM calculate_confidence_metrics(v_probabilities);
  
  -- Calculate dynamic threshold based on turn progress, candidate count, and margin
  v_dynamic_threshold := calculate_dynamic_threshold(
    v_total_turns,
    v_max_turns,
    v_candidate_count,
    v_confidence_metrics.margin
  );
  
  -- Make guess decision using algorithm function with dynamic threshold
  v_should_guess := should_guess(v_probabilities, v_dynamic_threshold);
  
  -- Get top candidate for guess
  SELECT elem INTO v_top_candidate
  FROM jsonb_array_elements(v_candidates) elem
  ORDER BY (elem->>'confidence')::FLOAT DESC
  LIMIT 1;

  -- Apply guess policy using algorithm-based decision
  -- Guess if: at max_turns, algorithm says to guess, or only 1 candidate
  IF v_total_turns >= v_max_turns
     OR v_should_guess = TRUE
     OR v_candidate_count = 1
  THEN
    -- Build GUESS next_turn using pure formatter (SRP)
    v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
  ELSE
    -- Ask a question: call get_question with candidates
    -- Note: Select specific columns to avoid TupleDesc resource leak
    SELECT question_type, trait_id, geographic_region_id, question_text, question_reasoning 
    INTO v_question_record
    FROM get_question(p_session_id, v_candidates)
    LIMIT 1;
    
    IF v_question_record.question_type IS NULL THEN
      -- No differentiating questions available - fall back to guess
      -- This happens when remaining candidates share all traits/regions
      v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
    ELSE
      -- Build QUESTION next_turn using pure formatter (SRP)
      v_next_turn := build_question_turn(
        v_question_record.question_type,
        v_question_record.trait_id,
        v_question_record.geographic_region_id,
        v_question_record.question_text,
        v_question_record.question_reasoning,
        v_candidates
      );
    END IF;
  END IF;

  -- Store next_turn
  UPDATE game_sessions
  SET next_turn = v_next_turn
  WHERE id = p_session_id;

END;
$$;


ALTER FUNCTION "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) owner TO "postgres";


comment ON function "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) IS 'Orchestrates next turn decision: guess or question using algorithm functions.

Parameters:
- p_session_id: Session ID
- p_candidates: Candidates JSONB array (caller must provide)

Responsibilities (SRP - Orchestration only):
1. Get/validate candidates
2. Extract confidence scores and convert to probabilities using softmax_probabilities()
3. Calculate confidence metrics using calculate_confidence_metrics()
4. Calculate dynamic threshold using calculate_dynamic_threshold()
5. Make guess decision using should_guess() with dynamic threshold
6. Call get_question() if asking question (delegates to question domain)
7. Call build_guess_turn() or build_question_turn() for formatting (pure functions)
8. Update database with next_turn

Algorithm Integration:
- Uses softmax_probabilities() to convert scores to probability distribution
- Uses calculate_confidence_metrics() for top_prob, margin, normalized_entropy
- Uses calculate_dynamic_threshold() for adaptive guess threshold based on:
  * Turn progress (more aggressive as game progresses)
  * Candidate count (bonus when few candidates remain)
  * Margin between top candidates (bonus when clear leader)
- Uses should_guess() with dynamic threshold for decision

Returns next_turn JSONB structure:
- {"action": "guess", "place_id": "...", "place_name": "...", "candidates": [...]}
- {"action": "question", "question_id": "...", "question_text": "...", "candidates": [...]}
- NULL (if no candidates available)

Called by:
- start_game() after creating new session (fetches candidates first)
- handle_question() after user answers question (passes candidates)
- handle_guess() after wrong guess (passes candidates)

Configuration (from game_logic.config):
- game.max_turns, scoring.temperature
- confidence.guess_threshold_max/min, threshold_floor/ceiling
- confidence.candidate_low_threshold, candidate_bonus
- confidence.margin_high_threshold, margin_bonus

Returns: VOID (side-effect only)';
