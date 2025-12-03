BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (3);


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
  );


-- ============================================================================
-- Schema Tests
-- ============================================================================
SELECT
  has_view ('public', 'user_stats', 'user_stats view exists');


-- ============================================================================
-- Access Tests
-- ============================================================================
-- Test: Authenticated users can access user_stats
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


-- Test: Anonymous users cannot access user_stats (permission denied)
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
