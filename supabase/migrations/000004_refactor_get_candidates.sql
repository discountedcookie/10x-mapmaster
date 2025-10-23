-- Migration: 0004_refactor_get_candidates
-- This migration refactors the get_candidates function to use a dynamic metadata filtering system.

-- 1. Add metadata_filter column to questions table
ALTER TABLE questions
ADD COLUMN metadata_filter JSONB;

COMMENT ON COLUMN questions.metadata_filter IS 'JSONB object describing a filter to apply to place descriptors. Used for hard filtering in get_candidates.';

-- 2. Update existing questions with metadata filters (using stable UUIDs)
UPDATE questions
SET metadata_filter = '{
  "filter_type": "string_in_list_check",
  "property_paths": ["type"],
  "operator": "in",
  "value": ["bridge", "tower"]
}'
WHERE id = '31743ac5-32df-4506-b162-1dfb579deae9';

UPDATE questions
SET metadata_filter = '{
  "filter_type": "numeric_check",
  "property_paths": ["height_meters", "elevation_meters"],
  "operator": ">=",
  "value": [200]
}'
WHERE id = '9847b09c-7f46-40f9-8f48-fb6d4506e11b';

UPDATE questions
SET metadata_filter = '{
  "filter_type": "string_in_list_check",
  "property_paths": ["class"],
  "operator": "in",
  "value": ["natural"]
}'
WHERE id = '09d330a5-3bd4-4ddb-b760-6410986ff51b';

-- 3. Create helper function to apply a single metadata filter
CREATE OR REPLACE FUNCTION apply_metadata_filter(
  descriptors jsonb,
  metadata_filter jsonb,
  answer boolean
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  filter_type text := metadata_filter->>'filter_type';
  property_paths jsonb := metadata_filter->'property_paths';
  operator text := metadata_filter->>'operator';
  value jsonb := metadata_filter->'value';

  -- Variables for iteration and storing the resolved value
  path_text text;
  extracted_value_text text;

  result boolean;
BEGIN
  -- 1. Extract the first non-NULL value by iterating through property_paths
  -- This handles Bug #1 (property extraction) and supports fallback paths
  IF jsonb_typeof(property_paths) = 'array' THEN
    FOR path_text IN SELECT jsonb_array_elements_text(property_paths)
    LOOP
      -- The #>> operator can take a text array to access nested paths
      -- Convert "extratags.height" to array for nested access
      extracted_value_text := descriptors#>>string_to_array(path_text, '.');

      -- Use the first non-null value we find
      IF extracted_value_text IS NOT NULL THEN
        EXIT;
      END IF;
    END LOOP;
  END IF;

  -- 2. Handle different filter types with corrected logic
  IF filter_type = 'numeric_check' THEN
    -- Handles Bug #2 (NULL handling) by coalescing to 0
    -- Extracts numeric value from array format
    IF operator = '>=' THEN
      result := COALESCE(extracted_value_text::numeric, 0) >= (value->>0)::numeric;
    ELSIF operator = '<=' THEN
      result := COALESCE(extracted_value_text::numeric, 0) <= (value->>0)::numeric;
    ELSIF operator = '>' THEN
      result := COALESCE(extracted_value_text::numeric, 0) > (value->>0)::numeric;
    ELSIF operator = '<' THEN
      result := COALESCE(extracted_value_text::numeric, 0) < (value->>0)::numeric;
    ELSE
      result := false;
    END IF;

  ELSIF filter_type = 'string_in_list_check' THEN
    -- Handles Bug #3 (type check operator) with correct comparison
    IF operator = 'in' THEN
      result := extracted_value_text = ANY(SELECT jsonb_array_elements_text(value));
    ELSE
      result := false;
    END IF;

  ELSIF filter_type = 'exists_check' THEN
    -- New filter type: check for property existence
    result := extracted_value_text IS NOT NULL;

  ELSE
    -- Default to false for unknown filter types
    result := false;
  END IF;

  -- 3. Compare the filter result with the user's answer
  IF answer THEN
    RETURN result;
  ELSE
    RETURN NOT result;
  END IF;
END;
$$;

-- 4. Update get_candidates function to use the new filtering logic
CREATE OR REPLACE FUNCTION get_candidates(
  session_id_param UUID
)
RETURNS TABLE (
  id uuid,
  name text,
  lat double precision,
  lng double precision,
  descriptors jsonb,
  semantic_similarity float,
  spatial_confidence float,
  composite_confidence float
)
LANGUAGE plpgsql
AS $$
DECLARE
  session_exists BOOLEAN;
BEGIN
  -- Ensure the session exists and has an embedding before running the query.
  SELECT EXISTS(SELECT 1 FROM game_sessions gs WHERE gs.id = session_id_param AND gs.description_embedding IS NOT NULL)
  INTO session_exists;

  IF NOT session_exists THEN
    RAISE EXCEPTION 'Session % not found or missing embedding', session_id_param;
  END IF;

  RETURN QUERY
  WITH
    session_context AS (
      SELECT
        gs.description_embedding,
        (
          SELECT array_agg(ga.place_id)
          FROM game_answers ga
          WHERE ga.session_id = session_id_param
            AND ga.answer_type = 'wrong_guess'
            AND ga.place_id IS NOT NULL
        ) as eliminated_place_ids,
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'question', q.text,
              'answer', ga.answer,
              'question_type', q.question_type,
              'geographic_region', q.geographic_region,
              'metadata_filter', q.metadata_filter
            ) ORDER BY ga.sequence_number
          )
          FROM game_answers ga
          JOIN questions q ON q.id = ga.question_id
          WHERE ga.session_id = session_id_param
            AND ga.answer_type = 'question_answer'
        ) as question_history
      FROM game_sessions gs
      WHERE gs.id = session_id_param
    ),
    initial_candidates AS (
      SELECT
        p.id,
        p.name,
        p.lat,
        p.lng,
        p.descriptors,
        p.geom,
        1 - (p.embedding <=> sc.description_embedding) as sem_similarity
      FROM places p, session_context sc
      WHERE p.embedding IS NOT NULL
        AND p.geom IS NOT NULL
        AND (sc.eliminated_place_ids IS NULL OR p.id <> ALL(sc.eliminated_place_ids))
        AND 1 - (p.embedding <=> sc.description_embedding) > 0.1
      ORDER BY p.embedding <=> sc.description_embedding
      LIMIT 20
    ),
    -- Geographic filtering: Apply ONLY bbox intersection for answered geographic questions
    geographic_filtered_candidates AS (
      SELECT
        ic.id,
        ic.name,
        ic.lat,
        ic.lng,
        ic.descriptors,
        ic.geom,
        ic.sem_similarity
      FROM initial_candidates ic
      WHERE (SELECT question_history FROM session_context) IS NULL OR NOT EXISTS (
        -- Geographic questions that answered YES: candidate must be WITHIN bbox
        SELECT 1
        FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
        WHERE q.value->>'question_type' = 'geographic'
          AND q.value->'geographic_region' IS NOT NULL
          AND (q.value->>'answer')::boolean = true
          AND NOT ST_Within(ic.geom, ST_MakeEnvelope(
            (q.value->'geographic_region'->'bbox'->0)::text::float,
            (q.value->'geographic_region'->'bbox'->1)::text::float,
            (q.value->'geographic_region'->'bbox'->2)::text::float,
            (q.value->'geographic_region'->'bbox'->3)::text::float,
            4326
          ))
      ) AND NOT EXISTS (
        -- Geographic questions that answered NO: candidate must be OUTSIDE bbox
        SELECT 1
        FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
        WHERE q.value->>'question_type' = 'geographic'
          AND q.value->'geographic_region' IS NOT NULL
          AND (q.value->>'answer')::boolean = false
          AND ST_Within(ic.geom, ST_MakeEnvelope(
            (q.value->'geographic_region'->'bbox'->0)::text::float,
            (q.value->'geographic_region'->'bbox'->1)::text::float,
            (q.value->'geographic_region'->'bbox'->2)::text::float,
            (q.value->'geographic_region'->'bbox'->3)::text::float,
            4326
          ))
      )
    ),
    -- Metadata filtering: Apply hard filters based on structured data from answered questions
    metadata_filtered_candidates AS (
      SELECT *
      FROM geographic_filtered_candidates gfc
      WHERE (SELECT question_history FROM session_context) IS NULL OR NOT EXISTS (
        SELECT 1
        FROM jsonb_array_elements((SELECT question_history FROM session_context)) q
        WHERE q.value->'metadata_filter' IS NOT NULL
          AND NOT apply_metadata_filter(gfc.descriptors, q.value->'metadata_filter', (q.value->>'answer')::boolean)
      )
    ),
    -- Semantic adjustment: Calculate similarity boost/penalty from answered semantic questions
    -- For each candidate, compute how well it matches YES questions vs NO questions
    semantic_adjustments AS (
      SELECT
        mfc.id,
        mfc.name,
        mfc.lat,
        mfc.lng,
        mfc.descriptors,
        mfc.geom,
        mfc.sem_similarity,
        -- Calculate semantic boost: positive for YES matches, negative for NO matches
        COALESCE(
          (
            SELECT AVG(
              CASE 
                -- If user answered YES, boost by similarity to question
                WHEN (qa.value->>'answer')::boolean = true 
                  THEN (1 - (place_emb.embedding <=> question_emb.embedding))
                -- If user answered NO, penalize by similarity to question  
                ELSE 
                  -(1 - (place_emb.embedding <=> question_emb.embedding))
              END
            )
            FROM jsonb_array_elements((SELECT question_history FROM session_context)) qa
            CROSS JOIN (SELECT embedding FROM places WHERE places.id = mfc.id) place_emb
            CROSS JOIN LATERAL (
              SELECT embedding 
              FROM questions 
              WHERE text = qa.value->>'question' 
                AND embedding IS NOT NULL
              LIMIT 1
            ) question_emb
            WHERE qa.value->>'question_type' = 'semantic'
          ),
          0.0
        ) as semantic_boost
      FROM metadata_filtered_candidates mfc
    ),
    filtered_candidates AS (
      SELECT
        sa.id,
        sa.name,
        sa.lat,
        sa.lng,
        sa.descriptors,
        sa.geom,
        -- Adjust semantic similarity with boost from answered questions
        GREATEST(0.1, LEAST(0.95, sa.sem_similarity + (sa.semantic_boost * 0.1))) as sem_similarity
      FROM semantic_adjustments sa
    ),
    candidates_with_centroid AS (
      SELECT
        *,
        ST_Centroid(ST_Collect(geom) OVER ()) as centroid_geom
      FROM filtered_candidates
    ),
    candidates_with_spatial_stats AS (
      SELECT
        *,
        MAX(ST_Distance(geom::geography, centroid_geom::geography)) OVER () as max_distance
      FROM candidates_with_centroid
    )
  SELECT
    c.id,
    c.name,
    c.lat,
    c.lng,
    c.descriptors,
    c.sem_similarity AS semantic_similarity,
    -- Per-place spatial confidence
    COALESCE(
      CASE
        WHEN c.max_distance IS NULL OR c.max_distance = 0 THEN 1.0
        ELSE 1.0 - (ST_Distance(c.geom::geography, c.centroid_geom::geography) / c.max_distance)
      END,
      0.0 -- Default confidence if no spatial stats can be computed
    ) AS spatial_confidence,
    -- Recalculated composite per place
    -- Strongly prioritize semantic similarity (0.95) over spatial clustering (0.05)
    -- This prevents geographically isolated candidates from being unfairly penalized
    -- Spatial is used only as a minor tiebreaker for similar semantic scores
    (c.sem_similarity * 0.95 +
     COALESCE(
       CASE
         WHEN c.max_distance IS NULL OR c.max_distance = 0 THEN 1.0
         ELSE 1.0 - (ST_Distance(c.geom::geography, c.centroid_geom::geography) / c.max_distance)
       END,
       0.0
     ) * 0.05) AS composite_confidence
  FROM candidates_with_spatial_stats c
  ORDER BY composite_confidence DESC;
END;
$$;
