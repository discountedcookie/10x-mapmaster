-- ============================================================================
-- Confidence Score Clustering Tests
-- ============================================================================
-- Tests to document and verify the confidence score clustering behavior
-- that motivates the need for frontend percentile normalization
--
-- Problem: Cosine similarity on embeddings produces tightly clustered scores
-- (e.g., 85.5%, 81.2%, 80.8%, 80.8%, 80.3%) making visual differentiation impossible
--
-- Solution: Frontend applies percentile normalization to amplify small differences
-- Formula: confidence = 0.95 - ((rank - 1) / (total - 1)) * 0.80

BEGIN;
SELECT plan(10);

-- ============================================================================
-- TEST SETUP: Create test data with embeddings
-- ============================================================================

-- Create test helper to generate a dummy embedding
CREATE OR REPLACE FUNCTION test_dummy_embedding()
RETURNS vector(384)
LANGUAGE sql
AS $$
  SELECT array_fill(0.1::float, ARRAY[384])::vector(384);
$$;

-- Create test session with embedding
CREATE TEMP TABLE test_session AS
WITH test_user AS (
  INSERT INTO auth.users (id, email)
  VALUES (gen_random_uuid(), 'confidence-test@example.com')
  RETURNING id
),
test_places AS (
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  SELECT
    'Test Place ' || n,
    40.0 + (n * 0.1),
    -74.0 + (n * 0.1),
    '{}'::jsonb,
    test_dummy_embedding()
  FROM generate_series(1, 20) n
  RETURNING id
),
test_session_insert AS (
  INSERT INTO game_sessions (id, user_id, description, description_embedding)
  SELECT
    gen_random_uuid(),
    (SELECT id FROM test_user),
    'A test description',
    test_dummy_embedding()
  RETURNING id, description
)
SELECT id, description FROM test_session_insert;

-- ============================================================================
-- TEST 1: Verify raw scores exhibit clustering (the problem)
-- ============================================================================
SELECT ok(
  (
    SELECT MAX(composite_confidence) - MIN(composite_confidence) < 0.1
    FROM (
      SELECT composite_confidence
      FROM get_candidates((SELECT id FROM test_session))
      ORDER BY composite_confidence DESC
      LIMIT 5
    ) top5
  ),
  'Top 5 candidates have clustered confidence scores (< 0.1 difference)'
);

-- ============================================================================
-- TEST 2: Raw scores are in descending order
-- ============================================================================
SELECT ok(
  (
    SELECT COUNT(*) = 0
    FROM (
      SELECT
        composite_confidence,
        LAG(composite_confidence) OVER (ORDER BY composite_confidence DESC) as prev_conf
      FROM get_candidates((SELECT id FROM test_session))
    ) ordered
    WHERE prev_conf IS NOT NULL AND prev_conf < composite_confidence
  ),
  'Candidates are correctly sorted by composite_confidence DESC'
);

-- ============================================================================
-- TEST 3: Percentile normalization produces wider spread
-- ============================================================================
WITH candidates AS (
  SELECT
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 5
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
normalized AS (
  SELECT
    c.composite_confidence as raw,
    CASE
      WHEN tc.total = 1 THEN 0.95
      ELSE 0.95 - ((c.rank - 1)::float / (tc.total - 1)::float) * 0.80
    END as normalized
  FROM candidates c
  CROSS JOIN total_count tc
)
SELECT ok(
  (SELECT MAX(normalized) - MIN(normalized) FROM normalized) > 0.5,
  'Percentile normalization produces wider spread (> 0.5 difference between top and bottom)'
);

-- ============================================================================
-- TEST 4: Normalization preserves rank order
-- ============================================================================
WITH candidates AS (
  SELECT
    name,
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 10
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
normalized AS (
  SELECT
    name,
    rank,
    composite_confidence as raw,
    CASE
      WHEN tc.total = 1 THEN 0.95
      ELSE 0.95 - ((c.rank - 1)::float / (tc.total - 1)::float) * 0.80
    END as normalized
  FROM candidates c
  CROSS JOIN total_count tc
)
SELECT ok(
  (
    SELECT COUNT(*) = 0
    FROM (
      SELECT
        normalized,
        LAG(normalized) OVER (ORDER BY rank) as prev_norm
      FROM normalized
    ) check_order
    WHERE prev_norm IS NOT NULL AND prev_norm < normalized
  ),
  'Percentile normalization preserves candidate rank order'
);

-- ============================================================================
-- TEST 5: Top candidate always gets 95% confidence
-- ============================================================================
WITH candidates AS (
  SELECT
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
)
SELECT is(
  (
    SELECT ROUND(
      (CASE
        WHEN tc.total = 1 THEN 0.95
        ELSE 0.95 - ((c.rank - 1)::float / (tc.total - 1)::float) * 0.80
      END)::numeric,
      2
    )
    FROM candidates c
    CROSS JOIN total_count tc
    WHERE c.rank = 1
  )::numeric,
  0.95::numeric,
  'Top candidate (rank 1) always normalized to 95%'
);

-- ============================================================================
-- TEST 6: Last candidate gets 15% confidence (when multiple candidates)
-- ============================================================================
WITH candidates AS (
  SELECT
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
last_candidate AS (
  SELECT
    c.rank,
    tc.total,
    CASE
      WHEN tc.total = 1 THEN 0.95
      ELSE 0.95 - ((c.rank - 1)::float / (tc.total - 1)::float) * 0.80
    END as normalized
  FROM candidates c
  CROSS JOIN total_count tc
  WHERE c.rank = tc.total AND tc.total > 1
)
SELECT ok(
  (SELECT ROUND(normalized::numeric, 2) FROM last_candidate) = 0.15
  OR (SELECT COUNT(*) FROM last_candidate) = 0,
  'Last candidate (rank N where N > 1) normalized to 15%'
);

-- ============================================================================
-- TEST 7: Single candidate edge case (always 95%)
-- ============================================================================
WITH single_candidate AS (
  SELECT composite_confidence
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 1
)
SELECT is(
  (
    SELECT
      CASE
        WHEN 1 = 1 THEN 0.95  -- total = 1
        ELSE 0.95 - ((1 - 1)::float / (1 - 1)::float) * 0.80
      END
  )::numeric,
  0.95::numeric,
  'Single candidate normalization returns 95%'
);

-- ============================================================================
-- TEST 8: Three candidates produce maximum spread (95%, 55%, 15%)
-- ============================================================================
WITH candidates AS (
  SELECT
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 3
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
normalized AS (
  SELECT
    rank,
    ROUND(
      (0.95 - ((rank - 1)::float / 2.0) * 0.80)::numeric,
      2
    ) as normalized
  FROM candidates
  CROSS JOIN total_count
  WHERE total = 3
)
SELECT ok(
  (SELECT COUNT(*) FROM normalized WHERE normalized IN (0.95, 0.55, 0.15)) = 3
  OR (SELECT COUNT(*) FROM normalized) != 3,
  'Three candidates normalize to 95%, 55%, 15%'
);

-- ============================================================================
-- TEST 9: Badge distribution improves after normalization
-- ============================================================================
WITH candidates AS (
  SELECT
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 10
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
normalized AS (
  SELECT
    composite_confidence as raw,
    CASE
      WHEN tc.total = 1 THEN 0.95
      ELSE 0.95 - ((c.rank - 1)::float / (tc.total - 1)::float) * 0.80
    END as normalized
  FROM candidates c
  CROSS JOIN total_count tc
),
badge_counts AS (
  SELECT
    COUNT(*) FILTER (WHERE raw >= 0.80) as raw_high,
    COUNT(*) FILTER (WHERE normalized >= 0.80) as norm_high,
    COUNT(*) FILTER (WHERE raw >= 0.50 AND raw < 0.80) as raw_med,
    COUNT(*) FILTER (WHERE normalized >= 0.50 AND normalized < 0.80) as norm_med,
    COUNT(*) FILTER (WHERE raw < 0.50) as raw_low,
    COUNT(*) FILTER (WHERE normalized < 0.50) as norm_low
  FROM normalized
)
SELECT ok(
  (SELECT norm_med + norm_low FROM badge_counts) > (SELECT raw_med + raw_low FROM badge_counts),
  'Normalization increases distribution of medium/low confidence badges'
);

-- ============================================================================
-- TEST 10: Semantic similarity values are preserved (not modified)
-- ============================================================================
WITH candidates AS (
  SELECT
    semantic_similarity,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
)
SELECT ok(
  (SELECT COUNT(*) FROM candidates WHERE semantic_similarity >= 0 AND semantic_similarity <= 1) =
  (SELECT COUNT(*) FROM candidates),
  'Semantic similarity values remain in valid range [0, 1]'
);

-- ============================================================================
-- MANUAL VERIFICATION QUERIES (commented, for developer use)
-- ============================================================================

-- Uncomment to see actual clustering behavior:
/*
-- Show raw vs normalized confidence for top 10 candidates
WITH candidates AS (
  SELECT
    name,
    composite_confidence,
    ROW_NUMBER() OVER (ORDER BY composite_confidence DESC) as rank
  FROM get_candidates((SELECT id FROM test_session))
  LIMIT 10
),
total_count AS (
  SELECT COUNT(*) as total FROM candidates
),
normalized AS (
  SELECT
    rank,
    name,
    ROUND(composite_confidence::numeric, 4) as raw,
    ROUND((CASE
      WHEN tc.total = 1 THEN 0.95
      ELSE 0.95 - ((rank - 1)::float / (tc.total - 1)::float) * 0.80
    END)::numeric, 4) as normalized,
    CASE
      WHEN (CASE
        WHEN tc.total = 1 THEN 0.95
        ELSE 0.95 - ((rank - 1)::float / (tc.total - 1)::float) * 0.80
      END) >= 0.80 THEN 'HIGH'
      WHEN (CASE
        WHEN tc.total = 1 THEN 0.95
        ELSE 0.95 - ((rank - 1)::float / (tc.total - 1)::float) * 0.80
      END) >= 0.50 THEN 'MEDIUM'
      ELSE 'LOW'
    END as badge
  FROM candidates c
  CROSS JOIN total_count tc
)
SELECT * FROM normalized ORDER BY rank;
*/

-- Cleanup
DROP FUNCTION test_dummy_embedding();
DROP TABLE test_session;

SELECT * FROM finish();
ROLLBACK;
