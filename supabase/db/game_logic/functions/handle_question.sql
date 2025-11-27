-- Function: handle_question
-- Category: game
-- Purpose: Handle question answer (SRP - Single Responsibility)
-- Spec: spec/algorithm.md#turn-flow
CREATE OR REPLACE FUNCTION "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) returns void language plpgsql
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_question_type question_type;
  v_trait_id TEXT;
  v_geographic_region_id UUID;
  v_question_text TEXT;
  v_candidates JSONB;
  v_candidates_after JSONB;
  v_temperature FLOAT;
BEGIN
  -- Get question details from next_turn
  v_question_type := (p_session_record.next_turn->>'question_type')::question_type;
  v_trait_id := p_session_record.next_turn->>'trait_id';
  v_geographic_region_id := (p_session_record.next_turn->>'geographic_region_id')::uuid;
  v_question_text := p_session_record.next_turn->>'question_text';

  IF v_question_type IS NULL THEN
    RAISE EXCEPTION 'Invalid next_turn: missing question_type';
  END IF;

  IF v_trait_id IS NULL AND v_geographic_region_id IS NULL THEN
    RAISE EXCEPTION 'Invalid next_turn: must have either trait_id or geographic_region_id';
  END IF;

  -- Get candidates from next_turn (state at answer time)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Get softmax temperature from config
  v_temperature := COALESCE(get_config_float('scoring.temperature'), 1.0);

  -- Update trait state (for trait arrays used by other functions)
  PERFORM apply_answer_to_session_state(
    p_session_record.id,
    p_answer,
    v_trait_id,
    v_geographic_region_id
  );

  -- Record answer with snapshot BEFORE adjustment
  PERFORM record_game_answer(
    p_session_record.id,
    v_trait_id,
    v_geographic_region_id,
    p_answer,
    p_session_record.place_id,
    v_question_text,
    v_candidates
  );

  -- Per spec: Apply answer based on question type
  -- Geographic = filter candidates (binary in/out)
  -- Semantic = adjust scores (power-law)
  IF v_question_type = 'geographic' THEN
    -- Filter candidates using PostGIS
    v_candidates_after := filter_candidates_for_geography(
      v_candidates,
      v_geographic_region_id,
      p_answer
    );
  ELSE
    -- Adjust scores using power-law scaling
    v_candidates_after := adjust_candidates_for_answer(
      v_candidates,
      v_trait_id,
      p_answer
    );
  END IF;

  -- Recalculate probabilities via softmax (per spec)
  v_candidates_after := apply_softmax_to_candidates(v_candidates_after, v_temperature);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) owner TO "postgres";


comment ON function "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) IS 'Handle question answer (YES/NO/NOT_SURE answer to a question).

Per spec (algorithm.md#turn-flow):
1. Record Answer
2. Geographic or Semantic?
   - Geographic → Filter Candidates (ST_Contains)
   - Semantic → Adjust Scores (Power-Law)
3. Recalculate Probabilities (softmax)
4. Decide Next Turn

Responsibilities (SRP):
- Fetch question details from next_turn
- Record answer with snapshot BEFORE adjustment
- Apply answer based on question type:
  - Geographic: filter_candidates_for_geography (binary in/out)
  - Semantic: adjust_candidates_for_answer (power-law scoring)
- Recalculate probabilities via softmax
- Continue game via decide_next_turn

Score Adjustment (semantic answers):
- Uses adjust_candidates_for_answer which calls adjust_score for each candidate
- new_score = old_score + adjustment (progressive, not recalculated)
- Adjustment magnitude uses power-law: base_weight * match_strength^beta

Storage strategy:
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once (snapshot before adjustment)
- Updated candidates stored in next next_turn

Returns: VOID (raises exception on error)';
