-- ============================================================================
-- Session-First Architecture Tests
-- ============================================================================
-- Tests for get_candidates, get_next_question, game_session_stats view
-- and the complete session-first game flow

BEGIN;
SELECT plan(8);

-- Create test helper to generate a dummy embedding
CREATE OR REPLACE FUNCTION test_dummy_embedding()
RETURNS vector(384)
LANGUAGE sql
AS $$
  SELECT array_fill(0.1::float, ARRAY[384])::vector(384);
$$;

-- Create temporary table to store test IDs
CREATE TEMP TABLE test_ids (
  user_id UUID,
  place1_id UUID,
  place2_id UUID,
  place3_id UUID,
  question1_id UUID,
  question2_id UUID,
  session_id UUID
);

-- ============================================================================
-- TEST SETUP: Create minimal test data
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_place1_id UUID;
  test_place2_id UUID;
  test_place3_id UUID;
  test_question1_id UUID;
  test_question2_id UUID;
  test_session_id UUID;
  test_embedding vector(384);
BEGIN
  -- Create a test user (using auth.users)
  INSERT INTO auth.users (id, email)
  VALUES (gen_random_uuid(), 'test@example.com')
  RETURNING id INTO test_user_id;

  -- Get a dummy embedding for testing
  SELECT test_dummy_embedding() INTO test_embedding;

  -- Create test places with embeddings and geometry
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Test Tower', 48.8584, 2.2945, '{"type": "tower", "class": "building"}'::jsonb, test_embedding)
  RETURNING id INTO test_place1_id;

  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Test Mountain', 35.3606, 138.7274, '{"type": "peak", "class": "natural"}'::jsonb, test_embedding)
  RETURNING id INTO test_place2_id;

  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Test Bridge', 37.8199, -122.4783, '{"type": "bridge", "class": "building"}'::jsonb, test_embedding)
  RETURNING id INTO test_place3_id;

  -- Create test questions with embeddings
  INSERT INTO questions (text, question_type, embedding)
  VALUES ('Is it a tower?', 'semantic', test_embedding)
  RETURNING id INTO test_question1_id;

  INSERT INTO questions (text, question_type, embedding)
  VALUES ('Is it in Europe?', 'geographic', test_embedding)
  RETURNING id INTO test_question2_id;

  -- Create a game session
  INSERT INTO game_sessions (id, user_id, description, description_embedding)
  VALUES (gen_random_uuid(), test_user_id, 'A tall tower', test_embedding)
  RETURNING id INTO test_session_id;

  -- Store IDs in temp table
  INSERT INTO test_ids VALUES (
    test_user_id, test_place1_id, test_place2_id, test_place3_id,
    test_question1_id, test_question2_id, test_session_id
  );
END $$;

-- ========================================================================
-- TEST 1: get_candidates() - Initial candidates
-- ========================================================================
SELECT is(
  (SELECT COUNT(*)::bigint FROM get_candidates((SELECT session_id FROM test_ids))),
  3::bigint,
  'get_candidates returns all 3 test places'
);

-- ========================================================================
-- TEST 2: get_next_question()
-- ========================================================================
SELECT ok(
  (SELECT COUNT(*)::bigint FROM get_next_question((SELECT session_id FROM test_ids), 10)) >= 2,
  'get_next_question returns available questions'
);

-- ========================================================================
-- TEST 3: Answer a question and test filtering
-- ========================================================================
INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
SELECT 
  session_id,
  question1_id,
  true,
  'question_answer',
  1,
  '{"place_ids": [], "confidence_scores": {"semantic": 0.5, "spatial": 0.5, "composite": 0.5}}'::jsonb
FROM test_ids;

SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM get_next_question((SELECT session_id FROM test_ids), 10)
    WHERE id = (SELECT question1_id FROM test_ids)
  ),
  'Answered question excluded from next questions'
);

-- ========================================================================
-- TEST 4: game_session_stats view
-- ========================================================================
SELECT is(
  (SELECT question_count FROM game_session_stats WHERE session_id = (SELECT session_id FROM test_ids)),
  1::bigint,
  'game_session_stats question count is correct'
);

SELECT is(
  (SELECT wrong_guess_count FROM game_session_stats WHERE session_id = (SELECT session_id FROM test_ids)),
  0::bigint,
  'game_session_stats wrong guess count is correct'
);

-- ========================================================================
-- TEST 5: Wrong guess and candidate elimination
-- ========================================================================
INSERT INTO game_answers (session_id, question_id, answer, answer_type, place_id, sequence_number, candidates_after)
SELECT 
  session_id,
  NULL,
  false,
  'wrong_guess',
  place1_id,
  2,
  '{"place_ids": [], "confidence_scores": {"semantic": 0, "spatial": 0, "composite": 0}}'::jsonb
FROM test_ids;

SELECT is(
  (SELECT COUNT(*)::bigint FROM get_candidates((SELECT session_id FROM test_ids))),
  2::bigint,
  'Wrong guess reduces candidate count to 2'
);

SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM get_candidates((SELECT session_id FROM test_ids))
    WHERE id = (SELECT place1_id FROM test_ids)
  ),
  'Wrong guess eliminates place from candidates'
);

-- ========================================================================
-- TEST 6: Multiple wrong guesses
-- ========================================================================
INSERT INTO game_answers (session_id, question_id, answer, answer_type, place_id, sequence_number, candidates_after)
SELECT 
  session_id,
  NULL,
  false,
  'wrong_guess',
  place2_id,
  3,
  '{"place_ids": [], "confidence_scores": {"semantic": 0, "spatial": 0, "composite": 0}}'::jsonb
FROM test_ids;

SELECT ok(
  (SELECT COUNT(*)::bigint FROM get_candidates((SELECT session_id FROM test_ids))) = 1
  AND (SELECT id FROM get_candidates((SELECT session_id FROM test_ids)) LIMIT 1) = (SELECT place3_id FROM test_ids),
  'Multiple wrong guesses leave only correct place'
);

-- Cleanup
DROP FUNCTION test_dummy_embedding();

SELECT * FROM finish();
ROLLBACK;
