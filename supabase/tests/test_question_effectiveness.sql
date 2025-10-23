-- ============================================================================
-- Question Effectiveness Batch Update Tests
-- ============================================================================
-- Tests for update_question_effectiveness_batch function

BEGIN;
SELECT plan(7);

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
  target_place_id UUID,
  other_place1_id UUID,
  other_place2_id UUID,
  question1_id UUID,
  question2_id UUID,
  question3_id UUID,
  session_id UUID,
  failed_session_id UUID,
  bounded_question_id UUID,
  bounded_session_id UUID
);

DO $$
DECLARE
  test_user_id UUID;
  test_target_place_id UUID;
  test_other_place1_id UUID;
  test_other_place2_id UUID;
  test_question1_id UUID;
  test_question2_id UUID;
  test_question3_id UUID;
  test_session_id UUID;
  test_embedding vector(384);
  failed_session_id UUID;
  bounded_question_id UUID;
  bounded_session_id UUID;
BEGIN
  -- Create test user
  INSERT INTO auth.users (id, email)
  VALUES (gen_random_uuid(), 'test-effectiveness@example.com')
  RETURNING id INTO test_user_id;

  -- Get dummy embedding
  SELECT test_dummy_embedding() INTO test_embedding;

  -- Create test places (target + distractors)
  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Target Place', 48.8584, 2.2945, '{"type": "tower"}'::jsonb, test_embedding)
  RETURNING id INTO test_target_place_id;

  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Distractor 1', 35.3606, 138.7274, '{"type": "mountain"}'::jsonb, test_embedding)
  RETURNING id INTO test_other_place1_id;

  INSERT INTO places (name, lat, lng, descriptors, embedding)
  VALUES ('Distractor 2', 37.8199, -122.4783, '{"type": "bridge"}'::jsonb, test_embedding)
  RETURNING id INTO test_other_place2_id;

  -- Create test questions with initial effectiveness = 0.5
  INSERT INTO questions (text, question_type, embedding, effectiveness_score, times_asked)
  VALUES ('Good question?', 'semantic', test_embedding, 0.5, 0)
  RETURNING id INTO test_question1_id;

  INSERT INTO questions (text, question_type, embedding, effectiveness_score, times_asked)
  VALUES ('Bad question?', 'semantic', test_embedding, 0.5, 0)
  RETURNING id INTO test_question2_id;

  INSERT INTO questions (text, question_type, embedding, effectiveness_score, times_asked)
  VALUES ('Neutral question?', 'semantic', test_embedding, 0.5, 0)
  RETURNING id INTO test_question3_id;

  -- Create successful game session
  INSERT INTO game_sessions (id, user_id, description, description_embedding, place_id, was_correct)
  VALUES (gen_random_uuid(), test_user_id, 'A tall tower', test_embedding, test_target_place_id, TRUE)
  RETURNING id INTO test_session_id;

  -- Simulate good question (narrowed from 3 to 1, kept target)
  INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
  VALUES (
    test_session_id,
    test_question1_id,
    true,
    'question_answer',
    1,
    jsonb_build_object(
      'place_ids', jsonb_build_array(test_target_place_id::text),
      'confidence_scores', jsonb_build_object('semantic', 0.8, 'spatial', 0.7, 'composite', 0.75)
    )
  );

  -- Simulate bad question (eliminated all candidates including target)
  INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
  VALUES (
    test_session_id,
    test_question2_id,
    false,
    'question_answer',
    2,
    jsonb_build_object(
      'place_ids', jsonb_build_array(),
      'confidence_scores', jsonb_build_object('semantic', 0, 'spatial', 0, 'composite', 0)
    )
  );

  -- Simulate neutral question (didn't narrow, but kept target)
  INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
  VALUES (
    test_session_id,
    test_question3_id,
    true,
    'question_answer',
    3,
    jsonb_build_object(
      'place_ids', jsonb_build_array(test_target_place_id::text),
      'confidence_scores', jsonb_build_object('semantic', 0.8, 'spatial', 0.7, 'composite', 0.75)
    )
  );

  -- Call the batch update function
  PERFORM update_question_effectiveness_batch(test_session_id);

  -- Create failed session for TEST 2
  INSERT INTO game_sessions (id, user_id, description, description_embedding, place_id, was_correct)
  VALUES (gen_random_uuid(), test_user_id, 'Wrong guess', test_embedding, test_other_place1_id, FALSE)
  RETURNING id INTO failed_session_id;

  INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
  VALUES (
    failed_session_id,
    test_question1_id,
    true,
    'question_answer',
    1,
    '{"place_ids": [], "confidence_scores": {"semantic": 0, "spatial": 0, "composite": 0}}'::jsonb
  );

  -- Create question with high effectiveness for TEST 3
  INSERT INTO questions (id, text, question_type, embedding, effectiveness_score, times_asked)
  VALUES (gen_random_uuid(), 'High effectiveness?', 'semantic', test_embedding, 0.95, 0)
  RETURNING id INTO bounded_question_id;

  INSERT INTO game_sessions (id, user_id, description, description_embedding, place_id, was_correct)
  VALUES (gen_random_uuid(), test_user_id, 'Test', test_embedding, test_target_place_id, TRUE)
  RETURNING id INTO bounded_session_id;

  INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number, candidates_after)
  VALUES (
    bounded_session_id,
    bounded_question_id,
    true,
    'question_answer',
    1,
    jsonb_build_object(
      'place_ids', jsonb_build_array(test_target_place_id::text),
      'confidence_scores', jsonb_build_object('semantic', 0.9, 'spatial', 0.9, 'composite', 0.9)
    )
  );

  -- Update effectiveness for bounded test
  PERFORM update_question_effectiveness_batch(bounded_session_id);

  -- Store IDs in temp table
  INSERT INTO test_ids VALUES (
    test_user_id, test_target_place_id, test_other_place1_id, test_other_place2_id,
    test_question1_id, test_question2_id, test_question3_id, test_session_id,
    failed_session_id, bounded_question_id, bounded_session_id
  );
END $$;

-- ========================================================================
-- TEST 1: Effectiveness update on successful session
-- ========================================================================
SELECT ok(
  (SELECT effectiveness_score FROM questions WHERE id = (SELECT question1_id FROM test_ids)) > 0.5,
  'Good question effectiveness increased'
);

SELECT ok(
  (SELECT effectiveness_score FROM questions WHERE id = (SELECT question2_id FROM test_ids)) < 0.5,
  'Bad question effectiveness decreased'
);

SELECT ok(
  (SELECT effectiveness_score FROM questions WHERE id = (SELECT question3_id FROM test_ids)) < 0.5,
  'Neutral question effectiveness decreased'
);

SELECT ok(
  (SELECT times_asked FROM questions WHERE id = (SELECT question1_id FROM test_ids)) = 1
  AND (SELECT times_asked FROM questions WHERE id = (SELECT question2_id FROM test_ids)) = 1
  AND (SELECT times_asked FROM questions WHERE id = (SELECT question3_id FROM test_ids)) = 1,
  'All questions have times_asked = 1'
);

-- ========================================================================
-- TEST 2: No update on failed session
-- ========================================================================
-- Store effectiveness before attempting failed session update
CREATE TEMP TABLE before_failed AS
  SELECT effectiveness_score FROM questions WHERE id = (SELECT question1_id FROM test_ids);

-- Try to update (should be no-op)
SELECT update_question_effectiveness_batch((SELECT failed_session_id FROM test_ids));

SELECT is(
  (SELECT effectiveness_score FROM questions WHERE id = (SELECT question1_id FROM test_ids)),
  (SELECT effectiveness_score FROM before_failed),
  'No effectiveness update for failed session'
);

-- ========================================================================
-- TEST 3: Effectiveness bounds [0.0, 1.0]
-- ========================================================================
SELECT ok(
  (SELECT effectiveness_score FROM questions WHERE id = (SELECT bounded_question_id FROM test_ids)) >= 0.0
  AND (SELECT effectiveness_score FROM questions WHERE id = (SELECT bounded_question_id FROM test_ids)) <= 1.0,
  'Effectiveness bounded within [0.0, 1.0]'
);

-- ========================================================================
-- TEST 4: times_asked increments correctly
-- ========================================================================
SELECT ok(
  (SELECT times_asked FROM questions WHERE id = (SELECT question1_id FROM test_ids)) > 0
  AND (SELECT times_asked FROM questions WHERE id = (SELECT question2_id FROM test_ids)) > 0
  AND (SELECT times_asked FROM questions WHERE id = (SELECT question3_id FROM test_ids)) > 0,
  'times_asked increments after questions are asked'
);

-- Cleanup
DROP FUNCTION test_dummy_embedding();

SELECT * FROM finish();
ROLLBACK;
