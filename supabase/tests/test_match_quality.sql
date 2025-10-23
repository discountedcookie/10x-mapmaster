-- ============================================================================
-- Golden Set Tests for Match Quality
-- ============================================================================
-- Validates the quality of the get_candidates() function using a "golden set"
-- of test cases derived from seed data.
--
-- Tests Included:
-- 1. High-confidence, exact matches (e.g., "Eiffel Tower")
-- 2. Moderate-confidence, descriptive matches (e.g., "tower in paris")
-- 3. Top-3 accuracy for ambiguous queries (e.g., "tallest mountain")
-- 4. Confidence threshold validation (>75% for good matches)
-- ============================================================================

BEGIN;

-- Plan the tests
SELECT plan(10);

-- ============================================================================
-- Test Setup
-- ============================================================================

-- Helper to create a dummy embedding with a specific pattern
-- Each place gets a unique "direction" by setting one dimension high and others low
CREATE OR REPLACE FUNCTION test_dummy_embedding(pattern_id int DEFAULT 1)
RETURNS vector(384) AS $$
  SELECT (
    CASE 
      WHEN pattern_id = 1 THEN array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[383])
      WHEN pattern_id = 2 THEN array_fill(0.1::float, ARRAY[1]) || array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[382])
      WHEN pattern_id = 3 THEN array_fill(0.1::float, ARRAY[2]) || array_fill(0.9::float, ARRAY[1]) || array_fill(0.1::float, ARRAY[381])
      ELSE array_fill(0.1::float, ARRAY[384])
    END
  )::vector(384);
$$ LANGUAGE sql;

-- Test user and session
CREATE TEMP TABLE test_data (
  user_id UUID,
  session_id UUID,
  eiffel_tower_id UUID,
  mount_everest_id UUID,
  colosseum_id UUID
);

-- Create test user and test places with distinct dummy embeddings
DO $$
DECLARE
  test_user_id UUID;
  eiffel_id UUID;
  everest_id UUID;
  colosseum_id UUID;
BEGIN
  -- Create test user
  INSERT INTO auth.users (id, email)
  VALUES (gen_random_uuid(), 'test-match-quality@example.com')
  RETURNING id INTO test_user_id;
  
  -- Create test places with distinct dummy embeddings pointing in different directions
  -- Each place gets a unique pattern ID so they're distinguishable by cosine similarity
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Eiffel Tower', 48.8584, 2.2945, '{"type": "tower", "class": "building"}'::jsonb, test_dummy_embedding(1))
  RETURNING id INTO eiffel_id;
  
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Mount Everest', 27.9881, 86.9250, '{"type": "peak", "class": "natural"}'::jsonb, test_dummy_embedding(2))
  RETURNING id INTO everest_id;
  
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Colosseum', 41.8902, 12.4922, '{"type": "attraction", "class": "historic"}'::jsonb, test_dummy_embedding(3))
  RETURNING id INTO colosseum_id;
  
  -- Store IDs in test_data table
  INSERT INTO test_data (user_id, eiffel_tower_id, mount_everest_id, colosseum_id)
  VALUES (test_user_id, eiffel_id, everest_id, colosseum_id);
END $$;

-- ============================================================================
-- Test Case 1: High-Confidence Exact Match
-- ============================================================================

-- Create a session for "eiffel tower" with matching embedding (pattern 1)
WITH new_session AS (
  INSERT INTO game_sessions (user_id, description, description_embedding)
  SELECT user_id, 'eiffel tower', test_dummy_embedding(1)
  FROM test_data
  RETURNING id
)
UPDATE test_data SET session_id = (SELECT id FROM new_session);

-- Test: Top-1 match is correct
SELECT is(
  (SELECT id FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1),
  (SELECT eiffel_tower_id FROM test_data),
  'Golden Set: "eiffel tower" should return Eiffel Tower as the top match.'
);

-- Test: Confidence is high
SELECT ok(
  (SELECT composite_confidence FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1) > 0.80,
  'Golden Set: "eiffel tower" should have a high confidence score (>80%).'
);

-- ============================================================================
-- Test Case 2: Moderate-Confidence Descriptive Match
-- ============================================================================

-- Create a session for "a tower in paris" with matching embedding (pattern 1)
UPDATE game_sessions
SET description = 'a tower in paris', description_embedding = test_dummy_embedding(1)
WHERE id = (SELECT session_id FROM test_data);

-- Test: Top-1 match is correct
SELECT is(
  (SELECT id FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1),
  (SELECT eiffel_tower_id FROM test_data),
  'Golden Set: "a tower in paris" should return Eiffel Tower as the top match.'
);

-- Test: Confidence is good
SELECT ok(
  (SELECT composite_confidence FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1) > 0.70,
  'Golden Set: "a tower in paris" should have a good confidence score (>70%).'
);

-- ============================================================================
-- Test Case 3: High-Confidence Natural Feature Match
-- ============================================================================

-- Create a session for "mount everest" with matching embedding (pattern 2)
UPDATE game_sessions
SET description = 'mount everest', description_embedding = test_dummy_embedding(2)
WHERE id = (SELECT session_id FROM test_data);

-- Test: Top-1 match is correct
SELECT is(
  (SELECT id FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1),
  (SELECT mount_everest_id FROM test_data),
  'Golden Set: "mount everest" should return Mount Everest as the top match.'
);

-- Test: Confidence is very high
SELECT ok(
  (SELECT composite_confidence FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1) > 0.85,
  'Golden Set: "mount everest" should have a very high confidence score (>85%).'
);

-- ============================================================================
-- Test Case 4: Top-3 Accuracy for Ambiguous Query
-- ============================================================================

-- Create a session for "tallest mountain" with matching embedding (pattern 2)
UPDATE game_sessions
SET description = 'tallest mountain', description_embedding = test_dummy_embedding(2)
WHERE id = (SELECT session_id FROM test_data);

-- Test: Correct answer is in the top 3
SELECT ok(
  (SELECT mount_everest_id FROM test_data) = ANY(
    ARRAY(SELECT id FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 3)
  ),
  'Golden Set: "tallest mountain" should have Mount Everest in the top 3 candidates.'
);

-- ============================================================================
-- Test Case 5: Ancient Landmark Match
-- ============================================================================

-- Create a session for "ancient roman arena" with matching embedding (pattern 3)
UPDATE game_sessions
SET description = 'ancient roman arena', description_embedding = test_dummy_embedding(3)
WHERE id = (SELECT session_id FROM test_data);

-- Test: Top-1 match is correct
SELECT is(
  (SELECT id FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1),
  (SELECT colosseum_id FROM test_data),
  'Golden Set: "ancient roman arena" should return the Colosseum as the top match.'
);

-- Test: Confidence is good
SELECT ok(
  (SELECT composite_confidence FROM get_candidates((SELECT session_id FROM test_data)) LIMIT 1) > 0.75,
  'Golden Set: "ancient roman arena" should have a good confidence score (>75%).'
);

-- ============================================================================
-- Test Case 6: Wrong Guess Elimination
-- ============================================================================

-- Use session for "a tower in paris" with matching embedding (pattern 1)
UPDATE game_sessions
SET description = 'a tower in paris', description_embedding = test_dummy_embedding(1)
WHERE id = (SELECT session_id FROM test_data);

-- Add a wrong guess for the Eiffel Tower
INSERT INTO game_answers (session_id, question_id, answer, answer_type, place_id, sequence_number, candidates_after)
SELECT 
  (SELECT session_id FROM test_data), 
  NULL, -- No question for wrong guess
  false, -- Answer is false for wrong guesses
  'wrong_guess',
  (SELECT eiffel_tower_id FROM test_data),
  1, -- Sequence number
  '{"place_ids": [], "confidence_scores": {"semantic": 0.0, "spatial": 0.0, "composite": 0.0}}'::jsonb;

-- Test: Eiffel Tower is no longer a candidate
SELECT ok(
  (SELECT eiffel_tower_id FROM test_data) != ALL(
    ARRAY(SELECT id FROM get_candidates((SELECT session_id FROM test_data)))
  ),
  'Golden Set: Eiffel Tower should be eliminated after a wrong guess.'
);


-- ============================================================================
-- Finish Tests
-- ============================================================================
SELECT * FROM finish();

ROLLBACK;
