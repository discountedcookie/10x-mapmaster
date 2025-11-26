-- Function: select_best_question
-- Category: algorithm
-- Purpose: Select best question (geographic or semantic) based on split quality
-- Spec: openspec/specs/algorithm/spec.md#question-selection-algorithm
-- Spec: openspec/specs/algorithm/spec.md#geographic-vs-semantic-questions
CREATE OR REPLACE FUNCTION select_best_question (
  p_session_id UUID,
  p_candidates JSONB,
  p_geographic_preference_threshold FLOAT DEFAULT 0.7,
  p_min_split_quality FLOAT DEFAULT 0.6
) returns TABLE (
  question_type TEXT,
  trait_id TEXT,
  geographic_region_id UUID,
  question_text TEXT,
  split_quality FLOAT
) language plpgsql AS $$
DECLARE
  v_candidate_count INT;
  v_best_geo_question RECORD;
  v_best_semantic_question RECORD;
  v_asked_trait_ids TEXT[];
  v_asked_region_ids UUID[];
BEGIN
  v_candidate_count := jsonb_array_length(p_candidates);
  
  IF v_candidate_count <= 1 THEN
    RETURN;  -- No point asking questions with 0-1 candidates
  END IF;
  
  -- Get already-asked trait IDs and region IDs for this session
  SELECT 
    array_agg(DISTINCT trait_id) FILTER (WHERE trait_id IS NOT NULL),
    array_agg(DISTINCT geographic_region_id) FILTER (WHERE geographic_region_id IS NOT NULL)
  INTO v_asked_trait_ids, v_asked_region_ids
  FROM game_answers
  WHERE session_id = p_session_id;
  
  v_asked_trait_ids := COALESCE(v_asked_trait_ids, ARRAY[]::TEXT[]);
  v_asked_region_ids := COALESCE(v_asked_region_ids, ARRAY[]::UUID[]);
  
  -- Find best geographic question
  SELECT * INTO v_best_geo_question
  FROM get_geographic_questions(p_session_id, p_candidates)
  WHERE geographic_region_id != ALL(v_asked_region_ids)
  ORDER BY split_quality DESC
  LIMIT 1;
  
  -- Find best semantic question
  SELECT * INTO v_best_semantic_question
  FROM get_semantic_questions(p_session_id, p_candidates)
  WHERE trait_id != ALL(v_asked_trait_ids)
  ORDER BY split_quality DESC
  LIMIT 1;
  
  -- Decision: prefer geographic if split quality >= threshold
  IF v_best_geo_question.split_quality >= p_geographic_preference_threshold THEN
    RETURN QUERY SELECT 
      'geographic'::TEXT,
      NULL::TEXT,
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
      NULL::TEXT,
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


ALTER FUNCTION select_best_question (UUID, JSONB, FLOAT, FLOAT) owner TO postgres;


comment ON function select_best_question (UUID, JSONB, FLOAT, FLOAT) IS 'Selects best question using geographic vs semantic decision logic.

Decision rules:
1. If best geographic split >= geographic_preference_threshold, use geographic
2. Else use whichever has higher split_quality
3. Filter out already-asked questions

Parameters:
- p_geographic_preference_threshold: Threshold to prefer geographic (default 0.7)
- p_min_split_quality: Minimum acceptable split quality (default 0.6)

Returns: question_type, trait_id OR geographic_region_id, question_text, split_quality';
