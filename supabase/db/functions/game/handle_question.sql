-- Function: handle_question
-- Category: game
-- Purpose: Handle question answer (SRP - Single Responsibility)
CREATE OR REPLACE FUNCTION "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) returns void language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_question_type question_type;
  v_trait_id TEXT;
  v_geographic_region_id UUID;
  v_question_text TEXT;
  v_candidates JSONB;
  v_candidates_after JSONB;
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

  -- Get candidates from next_turn (state at answer time - FREE!)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Update trait state
  PERFORM apply_answer_to_session_state(
    p_session_record.id,
    p_answer,
    v_trait_id,
    v_geographic_region_id
  );

  -- Record answer with snapshot BEFORE calling get_candidates
  PERFORM record_game_answer(
    p_session_record.id,
    v_trait_id,
    v_geographic_region_id,
    p_answer,
    p_session_record.place_id,
    v_question_text,
    v_candidates
  );

  -- Get candidates AFTER recording answer
  SELECT candidates
  INTO v_candidates_after
  FROM get_candidates(p_session_record.id);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) owner TO "postgres";


comment ON function "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) IS 'Handle question answer (YES/NO answer to a question).

Responsibilities (SRP):
- Fetch question details
- Apply answer based on question type (geographic/semantic)
- Record answer with snapshot at answer time
- Check if correct place survived
- Continue game

Storage strategy (no duplication):
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once
- AFTER state stored in next next_turn (becomes BEFORE for next answer)
- No redundancy: Each state stored exactly once

Optimization: Only 1 get_candidates call per turn

Returns: VOID (raises exception on error)
Supports OCP: New question types can be added without modifying existing handlers.
Extracted from play_turn for Single Responsibility Principle.';
