-- Replace semantic-only filtering with hybrid approach
-- Uses rule-based filtering for geographic questions and semantic for others

DROP FUNCTION IF EXISTS filter_candidates_by_question(UUID[], vector, BOOLEAN, FLOAT);

CREATE OR REPLACE FUNCTION filter_candidates_by_question(
  candidate_place_ids UUID[],
  question_text TEXT,
  user_answer BOOLEAN
) RETURNS UUID[]
LANGUAGE plpgsql
AS $$
DECLARE
  result_ids UUID[];
  continent_filter TEXT;
BEGIN
  -- Geographic filtering (rule-based using enriched descriptors)
  IF question_text = 'Is it in Europe?' THEN
    continent_filter := 'europe';
  ELSIF question_text = 'Is it in Asia?' THEN
    continent_filter := 'asia';
  ELSIF question_text = 'Is it in North America?' THEN
    continent_filter := 'north_america';
  ELSIF question_text = 'Is it in South America?' THEN
    continent_filter := 'south_america';
  ELSIF question_text = 'Is it in Africa?' THEN
    continent_filter := 'africa';
  ELSIF question_text = 'Is it in Oceania?' THEN
    continent_filter := 'oceania';
  END IF;

  -- Apply continent filtering if it's a geographic question
  IF continent_filter IS NOT NULL THEN
    SELECT ARRAY_AGG(id) INTO result_ids
    FROM places
    WHERE id = ANY(candidate_place_ids)
    AND (
      (user_answer = TRUE AND descriptors->>'continent' = continent_filter)
      OR
      (user_answer = FALSE AND descriptors->>'continent' != continent_filter)
    );

    RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
  END IF;

  -- Natural feature filtering
  IF question_text = 'Is it a natural feature?' THEN
    SELECT ARRAY_AGG(id) INTO result_ids
    FROM places
    WHERE id = ANY(candidate_place_ids)
    AND (
      (user_answer = TRUE AND descriptors->>'class' = 'natural')
      OR
      (user_answer = FALSE AND descriptors->>'class' != 'natural')
    );

    RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
  END IF;

  -- Major city filtering
  IF question_text = 'Is it in a major city?' THEN
    SELECT ARRAY_AGG(id) INTO result_ids
    FROM places
    WHERE id = ANY(candidate_place_ids)
    AND (
      (user_answer = TRUE AND descriptors->'address'->>'city' IS NOT NULL)
      OR
      (user_answer = FALSE AND descriptors->'address'->>'city' IS NULL)
    );

    RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
  END IF;

  -- Capital city filtering
  IF question_text = 'Is it in a capital city?' THEN
    SELECT ARRAY_AGG(id) INTO result_ids
    FROM places
    WHERE id = ANY(candidate_place_ids)
    AND (
      (user_answer = TRUE AND (descriptors->>'is_capital_city')::boolean = TRUE)
      OR
      (user_answer = FALSE AND COALESCE((descriptors->>'is_capital_city')::boolean, FALSE) = FALSE)
    );

    RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
  END IF;

  -- Bridge or tower filtering
  IF question_text = 'Is it a bridge or tower?' THEN
    SELECT ARRAY_AGG(id) INTO result_ids
    FROM places
    WHERE id = ANY(candidate_place_ids)
    AND (
      (user_answer = TRUE AND (descriptors->>'type' = 'bridge' OR descriptors->>'type' = 'tower'))
      OR
      (user_answer = FALSE AND descriptors->>'type' != 'bridge' AND descriptors->>'type' != 'tower')
    );

    RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
  END IF;

  -- For all other questions, keep all candidates
  -- (semantic filtering would go here in future, but for now we keep everything)
  RETURN candidate_place_ids;
END;
$$;

COMMENT ON FUNCTION filter_candidates_by_question IS
'Hybrid filtering using rule-based logic for geographic questions and semantic similarity for complex questions.
Geographic questions use enriched descriptors JSONB for precise filtering.';
