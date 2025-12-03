BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (14);


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
-- Schema Tests
-- ============================================================================
SELECT
  col_has_default (
    'public',
    'game_sessions',
    'id',
    'game_sessions.id has default'
  );


SELECT
  col_not_null (
    'public',
    'game_sessions',
    'id',
    'game_sessions.id is not null'
  );


SELECT
  col_type_is (
    'public',
    'game_sessions',
    'description',
    'text',
    'game_sessions.description is text'
  );


SELECT
  fk_ok (
    'public',
    'game_sessions',
    'place_id',
    'public',
    'places',
    'id',
    'FK: game_sessions.place_id references places.id'
  );


-- ============================================================================
-- RLS Tests
-- ============================================================================
SELECT
  ok (
    (
      SELECT
        relrowsecurity
      FROM
        pg_class
      WHERE
        relname = 'game_sessions'
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on game_sessions'
  );


-- Test: Authenticated users can query their own sessions
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


-- Test: Users cannot access other users' sessions
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


-- Test: Service role can access all sessions
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_sessions; $sql$,
    'Service role can access all sessions'
  );


-- Test: Users can insert their own sessions
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


-- Test: Users cannot insert sessions for other users (RLS violation)
SELECT
  throws_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES ('550e8400-e29b-41d4-a716-446655440002', 'Test description', 'en'); $sql$,
    '42501',
    'new row violates row-level security policy for table "game_sessions"'
  );


-- Test: Unauthenticated users cannot insert sessions (no auth.uid())
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
-- Test: Anonymous UUID user can create session with their user_id
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


-- Test: Anonymous UUID user can query their own sessions
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


-- Test: Different anonymous UUID users are isolated
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
