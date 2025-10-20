-- Create semantic filtering function using vector similarity
-- This function filters candidate places based on semantic similarity to the question

CREATE OR REPLACE FUNCTION filter_candidates_by_question(
  candidate_place_ids UUID[],
  question_emb vector(384),
  user_answer BOOLEAN,
  similarity_threshold FLOAT DEFAULT 0.4
) RETURNS UUID[]
LANGUAGE plpgsql
AS $$
DECLARE
  result_ids UUID[];
BEGIN
  -- Filter candidates based on semantic similarity to question
  -- If answer is YES: keep places with HIGH similarity to question
  -- If answer is NO: keep places with LOW similarity to question

  SELECT ARRAY_AGG(id) INTO result_ids
  FROM places
  WHERE id = ANY(candidate_place_ids)
    AND embedding IS NOT NULL
    AND (
      (user_answer = TRUE AND (1 - (embedding <=> question_emb)) >= similarity_threshold)
      OR
      (user_answer = FALSE AND (1 - (embedding <=> question_emb)) < similarity_threshold)
    );

  -- Return empty array if no results instead of NULL
  RETURN COALESCE(result_ids, ARRAY[]::UUID[]);
END;
$$;

-- Add comment explaining the function
COMMENT ON FUNCTION filter_candidates_by_question IS
'Filters candidate places using semantic similarity between place embeddings and question embedding.
YES answers keep high-similarity places, NO answers keep low-similarity places.';
