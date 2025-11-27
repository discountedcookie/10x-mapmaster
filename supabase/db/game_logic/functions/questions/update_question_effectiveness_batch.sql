-- Function: update_question_effectiveness_batch
-- Category: questions
-- Updates game_logic.question_stats based on game performance
CREATE OR REPLACE FUNCTION "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  answer_record RECORD;
  v_stat_id UUID;
  v_question_type question_type;
  precision_gain FLOAT;
  survival INT;
  score_delta FLOAT;
  new_effectiveness_score FLOAT;
  session_was_correct BOOLEAN;
BEGIN
  -- Only update effectiveness for successful/won sessions
  SELECT gs.was_correct INTO session_was_correct
  FROM game_sessions gs
  WHERE gs.id = session_id_param;

  -- Skip update if session was not won
  IF session_was_correct != TRUE THEN
    RETURN;
  END IF;

  FOR answer_record IN
    SELECT
      ga.trait_id,
      ga.geographic_region_id,
      ga.candidates::jsonb->'before_count' AS candidates_before_count,
      ga.candidates::jsonb->'after_count' AS candidates_after_count,
      ga.candidates::jsonb->'correct_survived' AS correct_place_survived
    FROM game_answers ga
    WHERE ga.session_id = session_id_param
      AND (ga.trait_id IS NOT NULL OR ga.geographic_region_id IS NOT NULL)
    ORDER BY ga.created_at ASC
  LOOP
    -- Determine question type
    v_question_type := CASE
      WHEN answer_record.trait_id IS NOT NULL THEN 'semantic'
      WHEN answer_record.geographic_region_id IS NOT NULL THEN 'geographic'
    END;

    -- Find or create game_logic.question_stats entry
    IF v_question_type = 'semantic' THEN
      SELECT id INTO v_stat_id
      FROM game_logic.question_stats
      WHERE trait_id = answer_record.trait_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO game_logic.question_stats (question_type, trait_id)
        VALUES ('semantic', answer_record.trait_id)
        RETURNING id INTO v_stat_id;
      END IF;
    ELSE
      SELECT id INTO v_stat_id
      FROM game_logic.question_stats
      WHERE geographic_region_id = answer_record.geographic_region_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO game_logic.question_stats (question_type, geographic_region_id)
        VALUES ('geographic', answer_record.geographic_region_id)
        RETURNING id INTO v_stat_id;
      END IF;
    END IF;

    -- Calculate precision gain
    precision_gain := (
      (answer_record.candidates_before_count::TEXT::INT - answer_record.candidates_after_count::TEXT::INT)::FLOAT 
      / GREATEST(1.0, answer_record.candidates_before_count::TEXT::INT::FLOAT)
    );

    -- Determine survival
    survival := CASE WHEN answer_record.correct_place_survived::TEXT::BOOLEAN THEN 1 ELSE -1 END;

    -- Calculate score delta
    score_delta := 0.04 * precision_gain * survival;

    -- Apply bonus/penalty adjustments
    IF precision_gain >= 0.30 AND survival = 1 THEN
      score_delta := score_delta + 0.01;
    END IF;

    IF precision_gain < 0.05 THEN
      score_delta := score_delta - 0.02;
    END IF;

    -- Get current effectiveness and calculate new value
    SELECT effectiveness_score INTO new_effectiveness_score
    FROM game_logic.question_stats
    WHERE id = v_stat_id;

    new_effectiveness_score := new_effectiveness_score + score_delta;

    -- Clamp to valid range [0.0, 1.0]
    new_effectiveness_score := LEAST(1.0, GREATEST(0.0, new_effectiveness_score));

    -- Update the stats
    UPDATE game_logic.question_stats
    SET
      times_asked = times_asked + 1,
      effectiveness_score = new_effectiveness_score
    WHERE id = v_stat_id;
  END LOOP;
END;
$$;


ALTER FUNCTION "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") IS 'Enhanced effectiveness update for v2 using precision-gain formula from PRD.
Formula:
  precision_gain = (before - after) / greatest(1, before)
  survival = CASE WHEN correct_place_survived THEN 1 ELSE -1 END
  score_delta = 0.04 * precision_gain * survival
  IF precision_gain >= 0.30 AND survival = 1 THEN score_delta += 0.01
  IF precision_gain < 0.05 THEN score_delta -= 0.02
  effectiveness_score = clamp(effectiveness_score + score_delta, 0.0, 1.0)

Also increments times_asked for each question used in the session.';
