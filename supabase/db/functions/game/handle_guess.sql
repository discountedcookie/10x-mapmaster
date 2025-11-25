-- Function: handle_guess
-- Category: game
-- Purpose: Handle guess confirmation (SRP - Single Responsibility)
CREATE OR REPLACE FUNCTION "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) returns void language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_eliminated_place_id UUID;
  v_candidates JSONB;
  v_candidates_after JSONB;
BEGIN
  -- Correct guess - mark session as won
  IF p_answer = TRUE THEN
    UPDATE game_sessions
    SET 
      place_id = (p_session_record.next_turn->>'place_id')::uuid,
      was_correct = TRUE,
      next_turn = NULL
    WHERE id = p_session_record.id;

    RETURN;
  END IF;

  -- Wrong guess - record it and continue
  v_eliminated_place_id := (p_session_record.next_turn->>'place_id')::uuid;

  -- Get candidates from next_turn (state at answer time - FREE!)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Record wrong guess (metrics derived later, not stored)
  PERFORM record_game_answer(
    p_session_record.id,
    NULL,  -- No trait
    NULL,  -- No geographic region
    FALSE,
    v_eliminated_place_id,
    NULL,
    v_candidates
  );

  -- Get candidates AFTER removing wrong guess (ONLY call to get_candidates)
  -- get_candidates excludes places with game_answers entries (question_id IS NULL)
  SELECT candidates
  INTO v_candidates_after
  FROM get_candidates(p_session_record.id);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) owner TO "postgres";


comment ON function "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) IS 'Handle guess confirmation (YES/NO answer to a guess).

Responsibilities (SRP):
- Correct guess: Mark session as won
- Wrong guess: Record answer with snapshot, exclude place, continue game

Storage strategy (no duplication):
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once
- AFTER state stored in next next_turn (becomes BEFORE for next answer)
- No redundancy: Each state stored exactly once

Returns: VOID (raises exception on error)
Extracted from play_turn for Single Responsibility Principle.';
