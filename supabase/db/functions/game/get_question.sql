-- Function: get_question
-- Category: game
-- Chooses the best question using LLM intelligence
CREATE OR REPLACE FUNCTION "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) returns TABLE (
  "question_type" question_type,
  "trait_id" TEXT,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql AS $$
DECLARE
  v_geographic_questions JSONB;
  v_semantic_questions JSONB;
BEGIN
  -- Get 3 best geographic questions
  SELECT jsonb_agg(
    jsonb_build_object(
      'type', 'geographic',
      'region_id', q.region_id,
      'name', q.region_name
    )
  ) INTO v_geographic_questions
  FROM get_geographic_questions(p_session_id, p_candidates, 5) q;

  -- Pass to LLM for selection
  RETURN QUERY SELECT * FROM get_llm_question(p_session_id, p_candidates, COALESCE(v_geographic_questions, '[]'::jsonb));
END;
$$;


ALTER FUNCTION "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) IS 'Gets 3 geographic + 3 semantic questions and uses LLM to select the best one.

Returns: question_type, trait_id/geographic_region_id, question_text';
