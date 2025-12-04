BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (12);


-- ============================================================================
-- Setup Test Users
-- ============================================================================
DELETE FROM game_answers;


DELETE FROM game_sessions;


INSERT INTO
  auth.users (id, aud, role, email)
VALUES
  (
    '550e8400-e29b-41d4-a716-446655440001',
    'authenticated',
    'authenticated',
    'test1@example.com'
  ),
  (
    '550e8400-e29b-41d4-a716-446655440002',
    'authenticated',
    'authenticated',
    'test2@example.com'
  );


-- ============================================================================
-- Game Sessions RLS Tests
-- ============================================================================
-- Test 1: Authenticated users can query their own sessions
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440001',
    TRUE
  );


SELECT
  lives_ok (
    $sql$ SELECT * FROM game_sessions WHERE user_id = '550e8400-e29b-41d4-a716-446655440001'; $sql$,
    'Authenticated users can query their own sessions'
  );


-- Test 2: Users cannot access other users' sessions
SELECT
  IS (
    (
      SELECT
        count(*)::INT
      FROM
        game_sessions
      WHERE
        user_id = '550e8400-e29b-41d4-a716-446655440002'
        AND auth.uid () = '550e8400-e29b-41d4-a716-446655440001'
    ),
    0,
    'Users cannot access other users sessions'
  );


-- Test 3: Service role can access all sessions
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_sessions; $sql$,
    'Service role can access all sessions'
  );


-- Test 4: Users can insert their own sessions
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440001',
    TRUE
  );


SELECT
  lives_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES ('550e8400-e29b-41d4-a716-446655440001', 'Test description', 'en'); $sql$,
    'Users can insert their own sessions'
  );


-- Test 5: Users cannot insert sessions for other users (RLS violation)
SELECT
  throws_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES ('550e8400-e29b-41d4-a716-446655440002', 'Test description', 'en'); $sql$,
    '42501',
    'new row violates row-level security policy for table "game_sessions"'
  );


-- Test 6: Unauthenticated users cannot insert sessions (no auth.uid())
SET
  local role anon;


SELECT
  set_config('request.jwt.claim.role', 'anon', TRUE);


SELECT
  set_config('request.jwt.claim.sub', '', TRUE);


SELECT
  throws_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES (NULL, 'Anonymous test', 'en'); $sql$,
    '42501',
    'new row violates row-level security policy for table "game_sessions"',
    'Unauthenticated users cannot create sessions (NULL user_id rejected)'
  );


-- ============================================================================
-- UUID-BASED ANONYMOUS USER TESTS
-- ============================================================================
-- Test 7: Anonymous UUID user can create session with their user_id
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440003',
    TRUE
  );


SELECT
  lives_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES ('550e8400-e29b-41d4-a716-446655440003', 'Anonymous UUID user test', 'en'); $sql$,
    'Anonymous UUID user can create session with their user_id'
  );


-- Test 8: Anonymous UUID user can query their own sessions
SELECT
  IS (
    (
      SELECT
        count(*)::INT
      FROM
        game_sessions
      WHERE
        user_id = '550e8400-e29b-41d4-a716-446655440003'
    ),
    1,
    'Anonymous UUID user can see their own session'
  );


-- Test 9: Different anonymous UUID users are isolated
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440004',
    TRUE
  );


SELECT
  IS (
    (
      SELECT
        count(*)::INT
      FROM
        game_sessions
      WHERE
        user_id = '550e8400-e29b-41d4-a716-446655440003'
    ),
    0,
    'Anonymous UUID user cannot see other anonymous users sessions'
  );


-- ============================================================================
-- Game Answers RLS Tests
-- ============================================================================
-- Test 10: Users can access answers for their sessions
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440001',
    TRUE
  );


SELECT
  lives_ok (
    $sql$ SELECT * FROM game_answers ga JOIN game_sessions gs ON ga.session_id = gs.id WHERE gs.user_id = '550e8400-e29b-41d4-a716-446655440001'; $sql$,
    'Users can access answers for their sessions'
  );


-- Test 11: Users cannot access answers for other users sessions
SELECT
  IS (
    (
      SELECT
        count(*)::INT
      FROM
        game_answers ga
        JOIN game_sessions gs ON ga.session_id = gs.id
      WHERE
        gs.user_id = '550e8400-e29b-41d4-a716-446655440002'
        AND auth.uid () = '550e8400-e29b-41d4-a716-446655440001'
    ),
    0,
    'Users cannot access answers for other users sessions'
  );


-- Test 12: Service role can access all answers
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_answers; $sql$,
    'Service role can access all game answers'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
