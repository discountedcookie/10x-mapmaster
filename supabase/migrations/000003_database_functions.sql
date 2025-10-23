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
    -- Strongly prioritize semantic similarity (0.95) over spatial clustering (0.05)
    (tc.sem_similarity * 0.95 + spatial_score * 0.05) as composite_confidence
  FROM temp_candidates tc
  ORDER BY (tc.sem_similarity * 0.95 + spatial_score * 0.05) DESC;

  -- Cleanup
  DROP TABLE temp_candidates;
END;
$$;

COMMENT ON FUNCTION match_places IS
'Enhanced vector similarity search with PostGIS spatial clustering analysis.
Returns candidates with semantic_similarity, spatial_confidence (based on geographic clustering),
and composite_confidence (weighted combination).';

-- ============================================================================
-- SESSION-FIRST CANDIDATE FILTERING
-- ============================================================================

-- Get candidates for a session (queries session state internally)
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
              'geographic_region', q.geographic_region
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
    -- Semantic adjustment: Calculate similarity boost/penalty from answered semantic questions
    -- For each candidate, compute how well it matches YES questions vs NO questions
    semantic_adjustments AS (
      SELECT
        gfc.id,
        gfc.name,
        gfc.lat,
        gfc.lng,
        gfc.descriptors,
        gfc.geom,
        gfc.sem_similarity,
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
            CROSS JOIN (SELECT embedding FROM places WHERE places.id = gfc.id) place_emb
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
      FROM geographic_filtered_candidates gfc
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
        GREATEST(0.0, LEAST(1.0, sa.sem_similarity + (sa.semantic_boost * 0.3))) as sem_similarity
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

COMMENT ON FUNCTION get_candidates IS
'Algorithmic candidate filtering using pure vector similarity and spatial operations.
Phase 1: Initial candidates via cosine similarity (pgvector <=> operator)
Phase 2: Geographic filtering - PostGIS bbox intersection for geographic questions
Phase 3: Semantic adjustment - Boost/penalize via similarity to answered semantic questions
Phase 4: Spatial confidence - Cluster analysis for geographic coherence
No hardcoded filters - all semantic matching via embeddings.
Takes only session_id - all context derived from database state.';

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
  questions_answered_count INT;
  max_questions INT := 5; -- Maximum questions per game session
BEGIN
  -- Check if maximum questions have been reached
  SELECT COUNT(*) INTO questions_answered_count
  FROM game_answers
  WHERE session_id = session_id_param
    AND answer_type = 'question_answer';

  -- If we've already asked max questions, return empty set
  IF questions_answered_count >= max_questions THEN
    RETURN;
  END IF;

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
    -- Semantic similarity for questions with embeddings
    -- Geographic questions without embeddings get a baseline score to ensure visibility
    CASE 
      WHEN q.embedding IS NOT NULL THEN 1 - (q.embedding <=> description_embedding)
      WHEN q.question_type = 'geographic' THEN 0.6  -- Baseline for geographic questions
      ELSE 0.0
    END as semantic_similarity
  FROM questions q
  WHERE 
    -- Exclude already answered questions in this session
    q.id NOT IN (
      SELECT question_id FROM game_answers 
      WHERE session_id = session_id_param
        AND question_id IS NOT NULL  -- Exclude wrong_guess rows (they have NULL question_id)
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
Stops returning questions once 5 questions have been answered (MAX_QUESTIONS).
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

-- Update question effectiveness for all questions in a session (batch)
CREATE OR REPLACE FUNCTION update_question_effectiveness_batch(
  session_id_param UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_place_id UUID;
  answer_record RECORD;
  initial_candidate_count INT;
  final_candidate_count INT;
  helped_narrow BOOLEAN;
  effectiveness_delta FLOAT;
  target_in_final BOOLEAN;
BEGIN
  -- Only update if session ended with correct guess
  SELECT place_id INTO target_place_id
  FROM game_sessions
  WHERE id = session_id_param AND was_correct = TRUE;

  IF target_place_id IS NULL THEN
    RETURN; -- Not a successful session, don't update
  END IF;

  -- For each question answer in the session
  FOR answer_record IN
    SELECT
      ga.question_id,
      ga.sequence_number,
      ga.candidates_after,
      LAG(ga.candidates_after) OVER (ORDER BY ga.sequence_number) as candidates_before
    FROM game_answers ga
    WHERE ga.session_id = session_id_param
      AND ga.answer_type = 'question_answer'
    ORDER BY ga.sequence_number
  LOOP
    -- Check if target place was in candidates before and after
    -- For first question, assume initial pool of 20 candidates if candidates_before is NULL
    IF answer_record.candidates_before IS NULL THEN
      initial_candidate_count := 20;
    ELSE
      initial_candidate_count := jsonb_array_length(
        answer_record.candidates_before->'place_ids'
      );
    END IF;

    final_candidate_count := jsonb_array_length(
      answer_record.candidates_after->'place_ids'
    );

    -- Check if target place is in final candidates
    target_in_final := target_place_id::text = ANY(
      ARRAY(
        SELECT jsonb_array_elements_text(
          answer_record.candidates_after->'place_ids'
        )
      )
    );

    -- Question helped if it narrowed candidates and kept target place
    helped_narrow := (
      final_candidate_count < initial_candidate_count
      AND target_in_final
    );

    -- Calculate effectiveness delta
    effectiveness_delta := CASE
      WHEN helped_narrow THEN 0.1
      WHEN final_candidate_count = 0 THEN -0.2 -- Eliminated all candidates (bad)
      WHEN NOT target_in_final THEN -0.15 -- Eliminated target place (very bad)
      ELSE -0.05 -- Didn't help narrow
    END;

    -- Update question effectiveness (bounded update with learning rate)
    UPDATE questions
    SET
      effectiveness_score = LEAST(1.0, GREATEST(0.0, effectiveness_score + 0.2 * effectiveness_delta)),
      times_asked = times_asked + 1
    WHERE id = answer_record.question_id;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION update_question_effectiveness_batch IS
'Updates question effectiveness for all questions in a session. Called when session ends with correct guess.
Evaluates whether each question helped narrow down to target place. Uses running average with bounds [0.0, 1.0].';
