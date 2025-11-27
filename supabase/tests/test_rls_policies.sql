BEGIN;


SET
  client_min_messages = warning;


-- Plan: 19 tests
SELECT
  plan (19);


-- Clean up any pre-existing test data for isolation
DELETE FROM game_answers;
DELETE FROM game_sessions;


-- Create test users
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


-- Test 3: Users cannot access other users' sessions
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


-- Test 4: Service role can access all sessions
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_sessions; $sql$,
    'Service role can access all sessions'
  );


-- Test 5: Users can insert their own sessions
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


-- Test 6: Users cannot insert sessions for other users (RLS violation)
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
  throws_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES ('550e8400-e29b-41d4-a716-446655440002', 'Test description', 'en'); $sql$,
    '42501',
    'new row violates row-level security policy for table "game_sessions"'
  );


-- Test 7: Anonymous users can insert anonymous sessions
SET
  local role anon;


SELECT
  set_config('request.jwt.claim.role', 'anon', TRUE);


SELECT
  set_config('request.jwt.claim.sub', '', TRUE);


SELECT
  lives_ok (
    $sql$ INSERT INTO game_sessions (user_id, description, language_code) VALUES (NULL, 'Anonymous test', 'en'); $sql$,
    'Anonymous users can create anonymous sessions'
  );


-- Test 8: Users can access answers for their sessions
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


-- Test 9: Users cannot access answers for other users sessions
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


-- Test 10: Public config is readable by everyone
SELECT
  lives_ok (
    $sql$ SELECT * FROM public.config; $sql$,
    'Public config is readable by everyone'
  );


-- Test 11: Authenticated cannot read game_logic.config (permission denied)
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  throws_ok (
    $sql$ SELECT * FROM game_logic.config; $sql$,
    '42501',
    'permission denied for table config'
  );


-- Test 12: Service role can manage game_logic.config
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ INSERT INTO game_logic.config (key, value, description) VALUES ('test.key', '"test_value"'::jsonb, 'Test setting'); $sql$,
    'Service role can manage game_logic config'
  );


-- Test 13: Authenticated users can access user_stats
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
    $sql$ SELECT * FROM user_stats; $sql$,
    'Authenticated users can access user_stats'
  );


-- Test 14: Anonymous users cannot access user_stats (permission denied)
SET
  local role anon;


SELECT
  set_config('request.jwt.claim.role', 'anon', TRUE);


SELECT
  set_config('request.jwt.claim.sub', '', TRUE);


SELECT
  throws_ok (
    $sql$ SELECT * FROM user_stats; $sql$,
    '42501',
    'permission denied for view user_stats',
    'Anonymous users cannot access user_stats'
  );


-- Test 15: Global stats accessible by service role
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT * FROM global_stats; $sql$,
    'Global stats is accessible by service role'
  );


-- Test 16: Places are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM places; $sql$,
    'Places are publicly readable'
  );


-- Test 17: Place traits are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM place_traits; $sql$,
    'Place traits are publicly readable'
  );


-- Test 18: Geographic regions are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM geographic_regions; $sql$,
    'Geographic regions are publicly readable'
  );


-- Test 19: Embeddings are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM embeddings; $sql$,
    'Embeddings are publicly readable'
  );


-- Test 20: Rate limit log accessible by service role
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_logic.rate_limit_log; $sql$,
    'Rate limit log is accessible by service role'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
