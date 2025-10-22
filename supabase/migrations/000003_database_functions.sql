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
  -- Don't filter by spatial distance - let all semantic matches through
  -- Spatial confidence affects the score but doesn't eliminate candidates
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
  ORDER BY (tc.sem_similarity * 0.6 + spatial_score * 0.4) DESC;

  -- Cleanup
  DROP TABLE temp_candidates;
END;
$$;

COMMENT ON FUNCTION match_places IS
'Enhanced vector similarity search with PostGIS spatial clustering analysis.
Returns candidates with semantic_similarity, spatial_confidence (based on geographic clustering),
and composite_confidence (weighted combination).';

-- ============================================================================
-- QUESTION MATCHING
-- ============================================================================

-- Get next question for a game session
CREATE OR REPLACE FUNCTION get_next_question(
  session_id_param UUID,
  match_count INT DEFAULT 10
)
RETURNS TABLE (
  id uuid,
  text text,
  question_type text,
  geographic_region jsonb,
  times_asked int,
  effectiveness_score double precision,
  semantic_similarity float
)
LANGUAGE plpgsql
AS $$
DECLARE
  description_embedding vector(384);
  answered_yes_bbox geometry;
  answered_q_type TEXT;
  answered_q_region JSONB;
BEGIN
  -- Get the description embedding from the game session
  SELECT gs.description_embedding INTO description_embedding
  FROM game_sessions gs
  WHERE gs.id = session_id_param;
  
  IF description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', session_id_param;
  END IF;
  
  -- Find if there's a geographic question answered YES in this session
  SELECT q.question_type, q.geographic_region
  INTO answered_q_type, answered_q_region
  FROM game_answers ga
  JOIN questions q ON q.id = ga.question_id
  WHERE ga.session_id = session_id_param
    AND ga.answer = TRUE
    AND q.question_type = 'geographic'
    AND q.geographic_region IS NOT NULL
  ORDER BY ga.sequence_number ASC
  LIMIT 1;
  
  -- If a geographic question was answered YES, create its bbox for filtering
  IF answered_q_type = 'geographic' AND answered_q_region IS NOT NULL THEN
    answered_yes_bbox := ST_MakeEnvelope(
      (answered_q_region->'bbox'->0)::text::float,
      (answered_q_region->'bbox'->1)::text::float,
      (answered_q_region->'bbox'->2)::text::float,
      (answered_q_region->'bbox'->3)::text::float,
      4326
    );
  END IF;
  
  -- Return questions matched by context, filtered by answer history and geographic constraints
  RETURN QUERY
  SELECT 
    q.id,
    q.text,
    q.question_type,
    q.geographic_region,
    q.times_asked,
    q.effectiveness_score,
    -- Semantic similarity only for questions with embeddings
    CASE 
      WHEN q.embedding IS NOT NULL THEN 1 - (q.embedding <=> description_embedding)
      ELSE 0.0
    END as semantic_similarity
  FROM questions q
  WHERE 
    -- Exclude already answered questions in this session
    q.id NOT IN (
      SELECT question_id FROM game_answers WHERE session_id = session_id_param
    )
    AND (
      -- Include all non-geographic questions that have embeddings
      (q.question_type != 'geographic' AND q.embedding IS NOT NULL)
      OR
      -- Include geographic questions based on bbox logic
      (q.question_type = 'geographic' AND (
        -- Include if no YES geographic answer yet (all geographic questions valid)
        answered_yes_bbox IS NULL
        OR
        -- Or if their bbox overlaps with the YES answer bbox
        (q.geographic_region IS NOT NULL AND ST_Intersects(
          answered_yes_bbox,
          ST_MakeEnvelope(
            (q.geographic_region->'bbox'->0)::text::float,
            (q.geographic_region->'bbox'->1)::text::float,
            (q.geographic_region->'bbox'->2)::text::float,
            (q.geographic_region->'bbox'->3)::text::float,
            4326
          )
        ))
      ))
    )
  ORDER BY 
    q.effectiveness_score DESC,
    semantic_similarity DESC,
    q.times_asked ASC
  LIMIT match_count;
END;
$$;

COMMENT ON FUNCTION get_next_question IS
'Returns next questions for a game session based on full session context.
Queries description_embedding from game_sessions and answer history from game_answers.
Semantic questions ranked by similarity to description. Geographic questions filtered spatially.
Takes only session_id - all context derived from database state.';

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
  question_record RECORD;
  bbox JSONB;
  bbox_geom geometry;
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

    -- Check if this is a geographic question with a bounding box
    SELECT question_type, geographic_region INTO question_record
    FROM questions
    WHERE text = question_text
    LIMIT 1;

    -- Geographic filtering using PostGIS bounding boxes
    IF question_record.question_type = 'geographic' AND question_record.geographic_region IS NOT NULL THEN
      bbox := question_record.geographic_region;
      
      -- Extract bbox coordinates: bbox->'bbox' is an array [min_lng, min_lat, max_lng, max_lat]
      bbox_geom := ST_MakeEnvelope(
        (bbox->'bbox'->0)::text::float,  -- min_lng
        (bbox->'bbox'->1)::text::float,  -- min_lat
        (bbox->'bbox'->2)::text::float,  -- max_lng
        (bbox->'bbox'->3)::text::float,  -- max_lat
        4326  -- WGS84
      );
      
      -- Filter candidates based on whether they're in the bounding box
      DELETE FROM filtered_candidates fc
      WHERE NOT (
        (user_answer = TRUE AND ST_Within(fc.geom, bbox_geom))
        OR
        (user_answer = FALSE AND NOT ST_Within(fc.geom, bbox_geom))
      );
      
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
