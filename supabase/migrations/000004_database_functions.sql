-- ============================================================================
-- Database Functions for Vector Similarity and Game Logic
-- ============================================================================
-- All database functions for vector search, filtering, and learning

-- ============================================================================
-- VECTOR SIMILARITY FUNCTIONS
-- ============================================================================

-- Match places using vector similarity with spatial confidence
CREATE OR REPLACE FUNCTION match_places(
  query_embedding vector(384),
  match_threshold float DEFAULT 0.1,
  match_count int DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  name text,
  lat double precision,
  lng double precision,
  descriptors jsonb,
  game_count int,
  semantic_similarity float,
  spatial_confidence float,
  composite_confidence float
)
LANGUAGE plpgsql
AS $$
DECLARE
  centroid_geom geometry;
  max_distance float;
  spatial_score float;
BEGIN
  -- Get initial candidates by semantic similarity
  CREATE TEMP TABLE temp_candidates AS
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    p.descriptors,
    p.game_count,
    p.geom,
    1 - (p.embedding <=> query_embedding) as sem_similarity
  FROM places p
  WHERE p.embedding IS NOT NULL
    AND p.geom IS NOT NULL
    AND 1 - (p.embedding <=> query_embedding) > match_threshold
  ORDER BY p.embedding <=> query_embedding
  LIMIT match_count;

  -- Calculate geographic centroid of candidates
  SELECT ST_Centroid(ST_Collect(geom)) INTO centroid_geom
  FROM temp_candidates;

  -- Calculate max distance from centroid (in meters)
  SELECT MAX(ST_Distance(geom::geography, centroid_geom::geography)) INTO max_distance
  FROM temp_candidates;

  -- Calculate spatial confidence score based on clustering
  IF max_distance IS NULL OR max_distance = 0 THEN
    spatial_score := 1.0;
  ELSIF max_distance <= 50000 THEN  -- Within 50km
    spatial_score := 1.0;
  ELSIF max_distance <= 200000 THEN  -- Within 200km
    spatial_score := 0.7 + (0.3 * (1 - (max_distance - 50000) / 150000));
  ELSIF max_distance <= 500000 THEN  -- Within 500km
    spatial_score := 0.3 + (0.4 * (1 - (max_distance - 200000) / 300000));
  ELSE  -- Scattered beyond 500km
    spatial_score := 0.2 * (1 - LEAST((max_distance - 500000) / 5000000, 1));
  END IF;

  -- Return candidates with confidence scores
  RETURN QUERY
  SELECT
    tc.id,
    tc.name,
    tc.lat,
    tc.lng,
    tc.descriptors,
    tc.game_count,
    tc.sem_similarity as semantic_similarity,
    spatial_score as spatial_confidence,
    (tc.sem_similarity * 0.6 + spatial_score * 0.4) as composite_confidence
  FROM temp_candidates tc
  WHERE
    -- Keep if close to centroid OR very high semantic match
    ST_Distance(tc.geom::geography, centroid_geom::geography) <= 500000
    OR tc.sem_similarity >= 0.85
  ORDER BY (tc.sem_similarity * 0.6 + spatial_score * 0.4) DESC;

  -- Cleanup
  DROP TABLE temp_candidates;
END;
$$;

COMMENT ON FUNCTION match_places IS
'Enhanced vector similarity search with PostGIS spatial clustering analysis.
Returns candidates with semantic_similarity, spatial_confidence (based on geographic clustering),
and composite_confidence (weighted combination). Filters geographic outliers unless semantic match is very high.';

-- Match questions using vector similarity
CREATE OR REPLACE FUNCTION match_questions(
  query_embedding vector(384),
  match_count int DEFAULT 10
)
RETURNS TABLE (
  id uuid,
  text text,
  times_asked int,
  effectiveness_score double precision,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    questions.id,
    questions.text,
    questions.times_asked,
    questions.effectiveness_score,
    1 - (questions.embedding <=> query_embedding) as similarity
  FROM questions
  WHERE questions.embedding IS NOT NULL
  ORDER BY questions.effectiveness_score DESC, questions.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

COMMENT ON FUNCTION match_questions IS
'Vector similarity search for questions ordered by effectiveness score.';

-- ============================================================================
-- FILTERING FUNCTIONS
-- ============================================================================

-- Filter candidates with cumulative question history
CREATE OR REPLACE FUNCTION filter_candidates_with_history(
  candidate_place_ids UUID[],
  question_history JSONB
)
RETURNS TABLE (
  id uuid,
  name text,
  lat double precision,
  lng double precision,
  descriptors jsonb,
  spatial_confidence float,
  composite_confidence float,
  semantic_similarity float
)
LANGUAGE plpgsql
AS $$
DECLARE
  question_item JSONB;
  question_text TEXT;
  user_answer BOOLEAN;
  continent_filter TEXT;
  centroid_geom geometry;
  max_distance float;
  spatial_score float;
BEGIN
  -- Start with all candidate places
  CREATE TEMP TABLE filtered_candidates AS
  SELECT p.id, p.name, p.lat, p.lng, p.descriptors, p.geom
  FROM places p
  WHERE p.id = ANY(candidate_place_ids);

  -- Apply filters from question history
  FOR question_item IN SELECT * FROM jsonb_array_elements(question_history)
  LOOP
    question_text := question_item->>'question';
    user_answer := (question_item->>'answer')::boolean;

    -- Geographic filtering (continents)
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
    ELSE
      continent_filter := NULL;
    END IF;

    IF continent_filter IS NOT NULL THEN
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND fc.descriptors->>'continent' = continent_filter)
        OR
        (user_answer = FALSE AND fc.descriptors->>'continent' != continent_filter)
      );
      continent_filter := NULL;
      CONTINUE;
    END IF;

    -- Natural feature filtering
    IF question_text = 'Is it a natural feature?' THEN
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND fc.descriptors->>'class' = 'natural')
        OR
        (user_answer = FALSE AND fc.descriptors->>'class' != 'natural')
      );
      CONTINUE;
    END IF;

    -- Major city filtering
    IF question_text = 'Is it in a major city?' THEN
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND fc.descriptors->'address'->>'city' IS NOT NULL)
        OR
        (user_answer = FALSE AND fc.descriptors->'address'->>'city' IS NULL)
      );
      CONTINUE;
    END IF;

    -- Capital city filtering
    IF question_text = 'Is it in a capital city?' THEN
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND (fc.descriptors->>'is_capital_city')::boolean = TRUE)
        OR
        (user_answer = FALSE AND COALESCE((fc.descriptors->>'is_capital_city')::boolean, FALSE) = FALSE)
      );
      CONTINUE;
    END IF;

    -- Bridge or tower filtering
    IF question_text = 'Is it a bridge or tower?' THEN
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND (fc.descriptors->>'type' = 'bridge' OR fc.descriptors->>'type' = 'tower'))
        OR
        (user_answer = FALSE AND fc.descriptors->>'type' != 'bridge' AND fc.descriptors->>'type' != 'tower')
      );
      CONTINUE;
    END IF;

  END LOOP;

  -- Recalculate spatial confidence on remaining candidates
  SELECT ST_Centroid(ST_Collect(geom)) INTO centroid_geom
  FROM filtered_candidates;

  IF centroid_geom IS NOT NULL THEN
    SELECT MAX(ST_Distance(geom::geography, centroid_geom::geography)) INTO max_distance
    FROM filtered_candidates;

    -- Calculate spatial confidence
    IF max_distance IS NULL OR max_distance = 0 THEN
      spatial_score := 1.0;
    ELSIF max_distance <= 50000 THEN
      spatial_score := 1.0;
    ELSIF max_distance <= 200000 THEN
      spatial_score := 0.7 + (0.3 * (1 - (max_distance - 50000) / 150000));
    ELSIF max_distance <= 500000 THEN
      spatial_score := 0.3 + (0.4 * (1 - (max_distance - 200000) / 300000));
    ELSE
      spatial_score := 0.2 * (1 - LEAST((max_distance - 500000) / 5000000, 1));
    END IF;
  ELSE
    spatial_score := 0.5;  -- Default if no geom available
  END IF;

  -- Return filtered candidates with updated confidence
  RETURN QUERY
  SELECT
    fc.id,
    fc.name,
    fc.lat,
    fc.lng,
    fc.descriptors,
    spatial_score as spatial_confidence,
    spatial_score as composite_confidence,
    0.0::double precision as semantic_similarity
  FROM filtered_candidates fc
  ORDER BY fc.name;

  -- Cleanup
  DROP TABLE filtered_candidates;
END;
$$;

COMMENT ON FUNCTION filter_candidates_with_history IS
'Applies cumulative filtering based on question history. Each question progressively narrows
the candidate pool. Recalculates spatial confidence after filtering to reflect tighter clustering.';

-- ============================================================================
-- LEARNING FUNCTIONS
-- ============================================================================

-- Update question effectiveness score
CREATE OR REPLACE FUNCTION update_question_effectiveness(
  question_id_param uuid,
  new_effectiveness float
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE questions
  SET
    effectiveness_score = (effectiveness_score + new_effectiveness) / 2.0,
    times_asked = times_asked + 1
  WHERE id = question_id_param;
END;
$$;

COMMENT ON FUNCTION update_question_effectiveness IS
'Updates a question''s effectiveness score using a running average.';

-- Update place embedding with weighted average (learning)
CREATE OR REPLACE FUNCTION update_place_embedding(
  place_id_param uuid,
  new_embedding vector(384),
  learning_rate float DEFAULT 0.3
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_embedding vector(384);
  current_count int;
  weight float;
BEGIN
  SELECT embedding, game_count INTO current_embedding, current_count
  FROM places
  WHERE id = place_id_param;

  -- If no existing embedding, just use the new one
  IF current_embedding IS NULL THEN
    UPDATE places
    SET
      embedding = new_embedding,
      game_count = game_count + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  -- Calculate weight based on game count (less weight to new data as count increases)
  weight := learning_rate / (1.0 + current_count * 0.1);

  -- Weighted average: old_embedding * (1 - weight) + new_embedding * weight
  UPDATE places
  SET
    embedding = (
      SELECT array_agg(
        (1.0 - weight) * old_val + weight * new_val
      )::vector(384)
      FROM unnest(current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val)
    ),
    game_count = game_count + 1
  WHERE id = place_id_param;
END;
$$;

COMMENT ON FUNCTION update_place_embedding IS
'Updates a place''s embedding using a weighted average. Weight decreases as game_count increases.';
