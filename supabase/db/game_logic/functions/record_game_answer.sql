-- Function: record_game_answer
-- Category: game
-- Purpose: DRY helper for recording answers in game_answers table
CREATE OR REPLACE FUNCTION "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) returns void language plpgsql
SET
  search_path = public,
  game_logic AS $$
BEGIN
  INSERT INTO game_answers (
    session_id,
    trait_id,
    geographic_region_id,
    answer,
    place_id,
    question_text,
    candidates
  ) VALUES (
    p_session_id,
    p_trait_id,
    p_geographic_region_id,
    p_answer,
    p_place_id,
    p_question_text,
    p_candidates
  );
END;
$$;


ALTER FUNCTION "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) IS 'Records answer with candidate snapshot at answer time.

Questions are generated on-the-fly from trait_id or geographic_region_id.';
