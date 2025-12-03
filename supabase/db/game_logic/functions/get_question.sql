-- Function: get_question
-- Category: game
-- Chooses the best question using algorithmic selection (split_quality)
-- Per docs/architecture/algorithm.md: "Selection is deterministic and algorithmic"
CREATE OR REPLACE FUNCTION "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) returns TABLE (
  "question_type" question_type,
  "trait_id" UUID,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_result RECORD;
  v_geographic_preference_threshold FLOAT;
  v_min_split_quality FLOAT;
  v_use_llm_questions BOOLEAN;
  v_language_code TEXT;
  v_user_description TEXT;
  v_generated_text TEXT;
  v_question_count INT;
  v_turn_number INT;
BEGIN
  -- Get configuration values
  v_geographic_preference_threshold := get_config_float('questions.geographic_preference_threshold', 0.7);
  v_min_split_quality := get_config_float('questions.min_split_quality', 0.3);
  v_use_llm_questions := get_config('questions.use_llm_generation')::text = 'true';
  
  -- Get language and description from session
  SELECT language_code, description INTO v_language_code, v_user_description
  FROM game_sessions
  WHERE id = p_session_id;
  v_language_code := COALESCE(v_language_code, 'en');
  
  -- Count existing questions to determine turn number
  -- Questions are stored in game_answers with trait_id or geographic_region_id set
  -- Turn 1 = first question (no questions yet), turn 2 = second question, etc.
  SELECT COUNT(*) INTO v_question_count
  FROM game_answers ga
  WHERE ga.session_id = p_session_id
    AND (ga.trait_id IS NOT NULL OR ga.geographic_region_id IS NOT NULL);
  v_turn_number := v_question_count + 1;
  
  -- Use algorithmic selection based on split_quality (per spec)
  -- select_best_question already filters out already-asked questions
  SELECT * INTO v_result
  FROM select_best_question(
    p_session_id, 
    p_candidates, 
    v_geographic_preference_threshold, 
    v_min_split_quality
  )
  LIMIT 1;
  
  IF v_result.question_type IS NULL THEN
    -- No questions available (all traits asked or no candidates)
    RETURN;
  END IF;
  
  -- Generate question text
  IF v_use_llm_questions THEN
    -- Use LLM to generate natural question text
    -- No fallback: if LLM fails, exception propagates and game crashes
    v_generated_text := generate_question_text(
      v_result.trait_id,
      v_result.geographic_region_id,
      v_language_code,
      v_user_description,
      v_turn_number
    );
    
    IF v_generated_text IS NULL OR v_generated_text = '' THEN
      RAISE EXCEPTION 'LLM returned empty question text for session %', p_session_id;
    END IF;
  ELSE
    -- LLM disabled: use templates (not a fallback, this is configured behavior)
    IF v_result.question_type = 'semantic' THEN
      v_generated_text := 'Does it have ' || COALESCE((SELECT clause FROM traits WHERE id = v_result.trait_id), v_result.trait_id) || '?';
    ELSIF v_result.question_type = 'geographic' THEN
      v_generated_text := 'Is it in ' || (SELECT name FROM geographic_regions WHERE id = v_result.geographic_region_id) || '?';
    ELSE
      RAISE EXCEPTION 'Unknown question type: %', v_result.question_type;
    END IF;
  END IF;
  
  RETURN QUERY SELECT
    v_result.question_type::question_type,
    v_result.trait_id,
    v_result.geographic_region_id,
    v_generated_text,
    ('Split quality: ' || COALESCE(round(v_result.split_quality::numeric, 2)::text, 'N/A'))::TEXT as question_reasoning;
END;
$$;


ALTER FUNCTION "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) owner TO "postgres";


comment ON function "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) IS 'Selects best question using algorithmic split_quality ranking.

Per docs/architecture/algorithm.md:
- Selection is deterministic and algorithmic
- LLM is used only to phrase questions (optional), not to choose them
- Uses select_best_question which considers geographic vs semantic preference

Returns: question_type, trait_id/geographic_region_id, question_text, reasoning';
