-- Function: get_question
-- Category: game
-- Chooses the best question using algorithmic selection (split_quality)
-- Per docs/architecture/algorithm.md: "Selection is deterministic and algorithmic"
CREATE OR REPLACE FUNCTION "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) returns TABLE (
  "question_type" question_type,
  "trait_id" TEXT,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_result RECORD;
BEGIN
  -- Get configuration values
  DECLARE
    v_geographic_preference_threshold FLOAT;
    v_min_split_quality FLOAT;
  BEGIN
    v_geographic_preference_threshold := get_config_float('questions.geographic_preference_threshold');
    
    v_min_split_quality := get_config_float('questions.min_split_quality');
    
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
  END;
  
  IF v_result.question_type IS NULL THEN
    -- No questions available (all traits asked or no candidates)
    RETURN;
  END IF;
  
  -- For now, use template-based question text (LLM generation disabled)
  RETURN QUERY SELECT
    v_result.question_type::question_type,
    v_result.trait_id,
    v_result.geographic_region_id,
    CASE 
      WHEN v_result.question_type = 'semantic' THEN 'Does it have ' || (SELECT clause FROM traits WHERE id = v_result.trait_id) || '?'
      WHEN v_result.question_type = 'geographic' THEN 'Is it in ' || (SELECT name FROM geographic_regions WHERE id = v_result.geographic_region_id) || '?'
      ELSE 'Unknown question type?'
    END,
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
