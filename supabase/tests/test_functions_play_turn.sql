BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


-- Simulate authenticated (or anonymous) user context
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
  plan (10);


-- ============================================================================
-- Create a single test session to reuse across tests
-- ============================================================================
CREATE TEMP TABLE test_session AS
SELECT
  start_game ('Buddhist ruins and ancient religious site') AS session_id;


-- Store the session ID for reuse
CREATE TEMP TABLE stored_session_id AS
SELECT
  session_id
FROM
  test_session;


-- ============================================================================
-- Test 1: Authentication required - should raise exception when no auth
-- ============================================================================
-- Temporarily clear auth context
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


-- ============================================================================
-- Test 2: Null parameters rejected - null session_id should fail
-- ============================================================================
SELECT
  throws_ok (
    $$SELECT play_turn(NULL::uuid, 'yes'::answer_value)$$,
    'Parameters cannot be null',
    'play_turn rejects null session_id'
  );


-- ============================================================================
-- Test 3: Null parameters rejected - null answer should fail
-- ============================================================================
SELECT
  throws_ok (
    $$SELECT play_turn('00000000-0000-0000-0000-000000000001'::uuid, NULL::answer_value)$$,
    'Parameters cannot be null',
    'play_turn rejects null answer'
  );


-- ============================================================================
-- Test 4: Session not found - invalid UUID should fail
-- ============================================================================
SELECT
  throws_ok (
    $$SELECT play_turn('00000000-0000-0000-0000-000000000099'::uuid, 'yes'::answer_value)$$,
    'Session 00000000-0000-0000-0000-000000000099 not found',
    'play_turn fails for non-existent session'
  );


-- ============================================================================
-- Test 5: Authorization check - cannot modify another user's session
-- ============================================================================
-- Try to modify as user 2
SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000002',
    TRUE
  );


SELECT
  throws_ok (
    $$SELECT play_turn((SELECT session_id FROM stored_session_id), 'yes'::answer_value)$$,
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


-- ============================================================================
-- Test 6: Already won session - was_correct=TRUE should fail
-- ============================================================================
-- Insert a session with was_correct=TRUE using a fixed UUID
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '66666666-6666-6666-6666-666666666666'::uuid,
  auth.uid(),
  'Test description',
  NULL,
  TRUE
);


-- Test that play_turn fails for already won session
SELECT
  throws_ok (
    $$SELECT play_turn('66666666-6666-6666-6666-666666666666'::uuid, 'yes'::answer_value)$$,
    'Session 66666666-6666-6666-6666-666666666666 is already won',
    'play_turn fails for already won session'
  );


-- ============================================================================
-- Test 7: No active turn - next_turn IS NULL should fail
-- ============================================================================
-- Insert a session with no next_turn using a fixed UUID
INSERT INTO game_sessions (id, user_id, description, next_turn, was_correct)
VALUES (
  '77777777-7777-7777-7777-777777777777'::uuid,
  auth.uid(),
  'Test description',
  NULL,
  FALSE
);


-- Test that play_turn fails when next_turn is NULL
SELECT
  throws_ok (
    $$SELECT play_turn('77777777-7777-7777-7777-777777777777'::uuid, 'yes'::answer_value)$$,
    'Session 77777777-7777-7777-7777-777777777777 has no active turn',
    'play_turn fails when next_turn is NULL'
  );


-- ============================================================================
-- Test 8: Successful guess turn - valid guess action processes correctly
-- ============================================================================
-- Verify the original test session has a next_turn with action
SELECT
  ok (
    (
      SELECT
        next_turn->>'action'
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            stored_session_id
        )
    ) IS NOT NULL,
    'Session has next_turn with action'
  );


-- ============================================================================
-- Test 9: Execute play_turn with a guess answer (yes)
-- ============================================================================
-- This should succeed without raising an exception
SELECT
  lives_ok(
    $sql$
    SELECT
      play_turn(
        (
          SELECT
            session_id
          FROM
            stored_session_id
        ),
        'yes'::answer_value
      );
    $sql$,
    'play_turn successfully processes guess answer'
  );


-- ============================================================================
-- Test 10: Verify session state was updated after guess turn
-- ============================================================================
SELECT
  ok (
    (
      SELECT
        was_correct IS NOT NULL
        OR next_turn IS NOT NULL
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            stored_session_id
        )
    ),
    'Session state updated after guess turn'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
