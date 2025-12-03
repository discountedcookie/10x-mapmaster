BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


-- Simulate authenticated user context for later tests
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
  plan (5);


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
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
      WHERE
        relname = 'config'
        AND nspname = 'game_logic'
    ),
    'RLS enabled on game_logic.config'
  );


-- Test: Authenticated cannot read game_logic.config (permission denied)
SELECT
  throws_ok (
    $sql$ SELECT * FROM game_logic.config; $sql$,
    '42501',
    'permission denied for table config'
  );


-- Test: Service role can manage game_logic.config
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ INSERT INTO game_logic.config (key, value, description) VALUES ('test.key', '"test_value"'::jsonb, 'Test setting'); $sql$,
    'Service role can manage game_logic config'
  );


-- ============================================================================
-- Config Key Validation
-- ============================================================================
-- Test: Critical config keys exist (functions depend on these)
SELECT
  ok (
    EXISTS (
      SELECT
        1
      FROM
        game_logic.config
      WHERE
        key = 'scoring.initial_candidate_threshold'
    ),
    'Critical config key exists: scoring.initial_candidate_threshold'
  );


-- ============================================================================
-- Rate Limit Log Access
-- ============================================================================
-- Test: Rate limit log accessible by service role
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_logic.rate_limit_log; $sql$,
    'Rate limit log is accessible by service role'
  );


-- ============================================================================
-- Behavior Tests (config controls game behavior)
-- ============================================================================
-- These tests verify settings in game_logic.config actually control game behavior
-- Note: Full behavior tests are in test_settings_control_behavior.sql (migrated here)
-- The comprehensive behavior test requires game session creation which is covered
-- in test_functions_start_game.sql


SELECT
  *
FROM
  finish ();


ROLLBACK;
