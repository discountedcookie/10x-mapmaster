BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (2);


-- ============================================================================
-- Schema Tests
-- ============================================================================
SELECT
  has_view (
    'public',
    'global_stats',
    'global_stats view exists'
  );


-- ============================================================================
-- Access Tests
-- ============================================================================
-- Test: Global stats accessible by service role
SET
  local role service_role;


SELECT
  lives_ok (
    $sql$ SELECT * FROM global_stats; $sql$,
    'Global stats is accessible by service role'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
