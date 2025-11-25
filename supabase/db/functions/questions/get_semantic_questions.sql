-- Function: get_semantic_questions
-- Category: questions
-- Returns traits to generate semantic questions from
CREATE OR REPLACE FUNCTION "public"."get_semantic_questions" (
  "p_session_id" "uuid",
  "p_limit" INTEGER DEFAULT NULL
) returns TABLE (
  "trait_id" TEXT,
  "trait_clause" TEXT,
  "trait_category" TEXT,
  "effectiveness_score" DOUBLE PRECISION,
  "times_asked" INTEGER
) language plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    pt.id,
    pt.clause,
    pt.category,
    COALESCE(qs.effectiveness_score, 0.5) as effectiveness_score,
    COALESCE(qs.times_asked, 0) as times_asked
  FROM place_traits pt
  LEFT JOIN question_stats qs ON qs.trait_id = pt.id
  WHERE
    -- Don't ask same trait twice
    pt.id NOT IN (
      SELECT ga.trait_id
      FROM game_answers ga
      WHERE ga.session_id = p_session_id
        AND ga.trait_id IS NOT NULL
    )
  ORDER BY effectiveness_score DESC, times_asked ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_semantic_questions" ("p_session_id" "uuid", "p_limit" INTEGER) owner TO "postgres";


comment ON function "public"."get_semantic_questions" ("p_session_id" "uuid", "p_limit" INTEGER) IS 'Returns traits to generate semantic questions from (e.g., "Does it have {trait_clause}?").

Filters by:
1. Not already asked in this session

Orders by:
1. Effectiveness score (descending)
2. Times asked (ascending)

Questions are generated on-the-fly from trait clauses, not stored.';
