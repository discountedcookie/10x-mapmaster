BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (1);


-- ============================================================================
-- Schema Tests
-- ============================================================================
SELECT
  has_view (
    'public',
    'game_session_state',
    'game_session_state view exists'
  );


-- Note: Access tests for game_session_state are covered indirectly through
-- game_sessions RLS tests, as the view exposes session state to owners only


SELECT
  *
FROM
  finish ();


ROLLBACK;
