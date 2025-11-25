-- Function: decide_next_turn
-- Category: game
-- Purpose: Decide whether to guess or ask a question based on current candidates
-- Builds complete next_turn JSONB with action and candidates
-- Updated to accept cached candidates to avoid redundant get_candidates calls
CREATE OR REPLACE FUNCTION "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) returns TABLE (session_id UUID) language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_candidates JSONB;
  v_candidate_count INT;
  v_top_confidence FLOAT;
  v_confidence_gap FLOAT;
  v_top_candidate JSONB;
  v_question_record RECORD;
  v_next_turn JSONB;
  v_total_turns INT;
  v_max_turns INT;
  v_guess_confidence_threshold FLOAT;
  v_guess_confidence_gap_threshold FLOAT;
  v_guess_high_confidence_threshold FLOAT;
BEGIN
  -- Get configuration from app_settings (FAIL if missing)
  v_max_turns := get_max_turns();
  
  SELECT value::FLOAT INTO STRICT v_guess_confidence_threshold 
  FROM app_settings WHERE key = 'guess_confidence_threshold';
  
  SELECT value::FLOAT INTO STRICT v_guess_confidence_gap_threshold
  FROM app_settings WHERE key = 'guess_confidence_gap_threshold';
  
  SELECT value::FLOAT INTO STRICT v_guess_high_confidence_threshold
  FROM app_settings WHERE key = 'guess_high_confidence_threshold';

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
    
    RETURN QUERY SELECT p_session_id;
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
    
    RETURN QUERY SELECT p_session_id;
    RETURN;
  END IF;

  -- Get top candidate's confidence and gap
  SELECT 
    COALESCE((elem->>'confidence')::float, 0.0),
    COALESCE((elem->>'confidence_gap')::float, 0.0),
    elem
  INTO v_top_confidence, v_confidence_gap, v_top_candidate
  FROM jsonb_array_elements(v_candidates) elem
  ORDER BY (elem->>'confidence')::float DESC
  LIMIT 1;

  -- Apply guess policy
  -- Guess if: at max_turns, only 1 candidate, super confident (>=1.0), or good confidence+gap
  IF v_total_turns >= v_max_turns
     OR v_candidate_count = 1
     OR v_top_confidence >= v_guess_high_confidence_threshold
     OR (v_top_confidence >= v_guess_confidence_threshold 
         AND v_confidence_gap >= v_guess_confidence_gap_threshold)
  THEN
    -- Build GUESS next_turn using pure formatter (SRP)
    v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
  ELSE
    -- Ask a question: call get_question with candidates
    SELECT * INTO v_question_record
    FROM get_question(p_session_id, v_candidates)
    LIMIT 1;
    
    IF v_question_record.question_type IS NULL THEN
      RAISE EXCEPTION 'Failed to choose next question for session %', p_session_id;
    END IF;
    
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

  -- Store next_turn
  UPDATE game_sessions
  SET next_turn = v_next_turn
  WHERE id = p_session_id;

  -- Return session_id
  RETURN QUERY SELECT p_session_id;
END;
$$;


ALTER FUNCTION "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) IS 'Orchestrates next turn decision: guess or question.

Parameters:
- p_session_id: Session ID
- p_candidates: Candidates JSONB array (caller must provide)

Responsibilities (SRP - Orchestration only):
1. Get/validate candidates
2. Apply guess policy (confidence + gap thresholds)
3. Call get_question() if asking question (delegates to question domain)
4. Call build_guess_turn() or build_question_turn() for formatting (pure functions)
5. Update database with next_turn

Returns next_turn JSONB structure:
- {"action": "guess", "place_id": "...", "place_name": "...", "candidates": [...]}
- {"action": "question", "question_id": "...", "question_text": "...", "candidates": [...]}
- NULL (if no candidates available)

Called by:
- start_game() after creating new session (fetches candidates first)
- handle_question() after user answers question (passes candidates)
- handle_guess() after wrong guess (passes candidates)

Configuration (from app_settings):
- max_turns, guess_confidence_threshold, guess_confidence_gap_threshold

Returns: session_id';
