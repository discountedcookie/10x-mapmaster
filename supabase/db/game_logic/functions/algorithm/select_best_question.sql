-- Function: select_best_question
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Select best question (geographic or semantic) based on split quality
-- Spec: openspec/specs/algorithm/spec.md#question-selection-algorithm
-- Spec: openspec/specs/algorithm/spec.md#geographic-vs-semantic-questions
CREATE OR REPLACE FUNCTION "game_logic"."select_best_question" (
  p_session_id UUID,
  p_candidates JSONB,
  p_geographic_preference_threshold FLOAT,
  p_min_split_quality FLOAT
) returns TABLE (
  question_type TEXT,
  trait_id UUID,
  geographic_region_id UUID,
  question_text TEXT,
  split_quality FLOAT
) language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_candidate_count INT;
  v_best_geo_question RECORD;
  v_best_semantic_question RECORD;
BEGIN
  v_candidate_count := jsonb_array_length(p_candidates);
  
  IF v_candidate_count <= 1 THEN
    RETURN;  -- No point asking questions with 0-1 candidates
  END IF;
  
  -- Find best geographic question (already filters out asked questions)
  SELECT * INTO v_best_geo_question
  FROM get_geographic_questions(p_session_id, p_candidates, 1);
  
  -- Find best semantic question (already filters out asked questions)
  SELECT * INTO v_best_semantic_question
  FROM get_semantic_questions(p_session_id, p_candidates, 1);
  
  -- Decision: prefer geographic if split quality >= threshold
  IF v_best_geo_question.split_quality >= p_geographic_preference_threshold THEN
    RETURN QUERY SELECT 
      'geographic'::TEXT,
      NULL::UUID,
      v_best_geo_question.geographic_region_id,
      v_best_geo_question.question_text,
      v_best_geo_question.split_quality;
    RETURN;
  END IF;
  
  -- Fall back to semantic if it has better quality
  IF v_best_semantic_question.split_quality >= COALESCE(v_best_geo_question.split_quality, 0) THEN
    RETURN QUERY SELECT 
      'semantic'::TEXT,
      v_best_semantic_question.trait_id,
      NULL::UUID,
      v_best_semantic_question.question_text,
      v_best_semantic_question.split_quality;
    RETURN;
  END IF;
  
  -- Use geographic if available (even if below threshold)
  IF v_best_geo_question.geographic_region_id IS NOT NULL THEN
    RETURN QUERY SELECT 
      'geographic'::TEXT,
      NULL::UUID,
      v_best_geo_question.geographic_region_id,
      v_best_geo_question.question_text,
      v_best_geo_question.split_quality;
    RETURN;
  END IF;
  
  -- Use semantic if available
  IF v_best_semantic_question.trait_id IS NOT NULL THEN
    RETURN QUERY SELECT 
      'semantic'::TEXT,
      v_best_semantic_question.trait_id,
      NULL::UUID,
      v_best_semantic_question.question_text,
      v_best_semantic_question.split_quality;
    RETURN;
  END IF;
  
  -- No questions available
  RETURN;
END;
$$;


ALTER FUNCTION "game_logic"."select_best_question" (UUID, JSONB, FLOAT, FLOAT) owner TO postgres;


comment ON function "game_logic"."select_best_question" (UUID, JSONB, FLOAT, FLOAT) IS 'Selects best question using geographic vs semantic decision logic.

Per spec (algorithm.md#geographic-vs-semantic-questions):
1. Calculate best geographic question split_quality
2. Calculate best semantic question split_quality
3. IF geographic_split >= geographic_preference_threshold → Ask geographic
4. ELSE → Ask whichever has higher split_quality

Decision rules:
1. If best geographic split >= threshold (default 0.7), use geographic (binary filter is simpler)
2. Else use whichever has higher split_quality
3. Already-asked questions filtered by get_geographic_questions and get_semantic_questions

Parameters:
- p_geographic_preference_threshold: Threshold to prefer geographic (default 0.7)
- p_min_split_quality: Minimum acceptable split quality (default 0.6)

Returns: question_type, trait_id OR geographic_region_id, question_text, split_quality

NOTE: This is an internal function that should be in game_logic schema (not client-accessible).';
