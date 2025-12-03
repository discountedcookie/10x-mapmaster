BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (4);


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
  fk_ok (
    'public',
    'game_answers',
    'session_id',
    'public',
    'game_sessions',
    'id',
    'FK: game_answers.session_id references game_sessions.id'
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
        relname = 'game_answers'
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on game_answers'
  );


-- Test: Users can access answers for their sessions
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


-- Test: Users cannot access answers for other users sessions
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
