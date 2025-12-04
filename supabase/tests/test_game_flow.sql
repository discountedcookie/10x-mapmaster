BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


-- Simulate authenticated user context
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000001',
    TRUE
  );


SELECT
  plan (12);


-- ============================================================================
-- Test: start_game function basic behavior
-- ============================================================================
-- Note: During pgTAP tests, generate_embedding returns zero vectors, so
-- candidate matching won't work. We test the function mechanics instead.

-- Test 1: start_game creates a session and returns a valid UUID
CREATE TEMP TABLE game1 AS
SELECT
  start_game ('Test description for game session') AS session_id;


SELECT
  ok (
    (
      SELECT
        session_id
      FROM
        game1
    ) IS NOT NULL,
    'start_game returns a session UUID'
  );


-- Test 2: Session is created with correct user_id
SELECT
  ok (
    (
      SELECT
        user_id
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            game1
        )
    ) = '00000000-0000-0000-0000-000000000001'::uuid,
    'Session created with correct user_id from auth context'
  );


-- Test 3: Session has description stored
SELECT
  ok (
    (
      SELECT
        description
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            game1
        )
    ) = 'Test description for game session',
    'Session stores the description'
  );


-- Test 4: Session has embedding_id (even if zero vector during tests)
SELECT
  ok (
    (
      SELECT
        embedding_id
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            game1
        )
    ) IS NOT NULL,
    'Session has embedding_id assigned'
  );


-- ============================================================================
-- Test: play_turn function validation
-- ============================================================================

-- Test 5: Authentication required - should raise exception when no auth
SELECT
  set_config('request.jwt.claim.sub', NULL, TRUE);


SELECT
  throws_ok (
    $$SELECT play_turn('00000000-0000-0000-0000-000000000001'::uuid, 'yes'::answer_value)$$,
    'Authentication required',
    'play_turn requires authentication'
  );


-- Restore auth context
SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000001',
    TRUE
  );


-- Test 6: Null parameters rejected - null session_id should fail
SELECT
  throws_ok (
    $$SELECT play_turn(NULL::uuid, 'yes'::answer_value)$$,
    'Parameters cannot be null',
    'play_turn rejects null session_id'
  );


-- Test 7: Null parameters rejected - null answer should fail
SELECT
  throws_ok (
    $$SELECT play_turn('00000000-0000-0000-0000-000000000001'::uuid, NULL::answer_value)$$,
    'Parameters cannot be null',
    'play_turn rejects null answer'
  );


-- Test 8: Session not found - invalid UUID should fail
SELECT
  throws_ok (
    $$SELECT play_turn('00000000-0000-0000-0000-000000000099'::uuid, 'yes'::answer_value)$$,
    'Session 00000000-0000-0000-0000-000000000099 not found',
    'play_turn fails for non-existent session'
  );


-- Test 9: Authorization check - cannot modify another user's session
-- Create a session owned by user 1
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '11111111-1111-1111-1111-111111111111'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'User 1 session',
  '{"action": "guess", "place_id": "00000000-0000-0000-0000-000000000001", "candidates": []}'::jsonb,
  FALSE
);


-- Try to modify as user 2
SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000002',
    TRUE
  );


SELECT
  throws_ok (
    $$SELECT play_turn('11111111-1111-1111-1111-111111111111'::uuid, 'yes'::answer_value)$$,
    'Not authorized to modify this session',
    'play_turn prevents unauthorized user from modifying another user session'
  );


-- Reset to user 1 for remaining tests
SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000001',
    TRUE
  );


-- Test 10: Already won session - was_correct=TRUE should fail
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '66666666-6666-6666-6666-666666666666'::uuid,
  auth.uid(),
  'Test description',
  NULL,
  TRUE
);


SELECT
  throws_ok (
    $$SELECT play_turn('66666666-6666-6666-6666-666666666666'::uuid, 'yes'::answer_value)$$,
    'Session 66666666-6666-6666-6666-666666666666 is already won',
    'play_turn fails for already won session'
  );


-- Test 11: No active turn - next_turn IS NULL should fail
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '77777777-7777-7777-7777-777777777777'::uuid,
  auth.uid(),
  'Test description',
  NULL,
  FALSE
);


SELECT
  throws_ok (
    $$SELECT play_turn('77777777-7777-7777-7777-777777777777'::uuid, 'yes'::answer_value)$$,
    'Session 77777777-7777-7777-7777-777777777777 has no active turn',
    'play_turn fails when next_turn is NULL'
  );


-- Test 12: play_turn with valid guess action succeeds
-- Create a session with a valid guess next_turn pointing to an existing place
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '88888888-8888-8888-8888-888888888888'::uuid,
  auth.uid(),
  'Test guess session',
  jsonb_build_object(
    'action', 'guess',
    'place_id', (SELECT id FROM places LIMIT 1),
    'candidates', '[]'::jsonb
  ),
  FALSE
);


SELECT
  lives_ok(
    $$SELECT play_turn('88888888-8888-8888-8888-888888888888'::uuid, 'yes'::answer_value)$$,
    'play_turn successfully processes guess answer'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
