BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


-- Enable pgTAP short-circuit detection for functions that call external services
DO $$ BEGIN PERFORM set_config('pgtap.version', '1.0', true); END $$;


SELECT
  plan (10);


-- ============================================================================
-- Test User Setup
-- ============================================================================
-- User 1: Primary test user (will own sessions)
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


-- ============================================================================
-- Test 1: Successful submission for needs_submission session (give_up action)
-- ============================================================================
-- Create a session in needs_submission state (next_turn has give_up action)
INSERT INTO game_sessions (
  id,
  user_id,
  description,
  language_code,
  next_turn,
  status,
  was_correct
)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000001',
  'Test place description',
  'en',
  '{"action": "give_up"}'::JSONB,
  'active',
  NULL
);


SELECT
  lives_ok(
    $$SELECT submit_place(
      '11111111-1111-1111-1111-111111111111'::UUID,
      'way/12345'
    )$$,
    'Successful submission for needs_submission session (give_up action)'
  );


-- Verify session was updated correctly
SELECT
  ok (
    (
      SELECT
        was_correct = FALSE
        AND next_turn IS NULL
        AND pending_review = TRUE
      FROM
        game_sessions
      WHERE
        id = '11111111-1111-1111-1111-111111111111'
    ),
    'Session updated with was_correct=FALSE, next_turn=NULL, pending_review=TRUE'
  );


-- ============================================================================
-- Test 2: Successful submission for needs_submission session (null next_turn)
-- ============================================================================
-- Create a session with null next_turn and was_correct not true
INSERT INTO game_sessions (
  id,
  user_id,
  description,
  language_code,
  next_turn,
  status,
  was_correct
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '00000000-0000-0000-0000-000000000001',
  'Another test place',
  'en',
  NULL,
  'active',
  NULL
);


SELECT
  lives_ok(
    $$SELECT submit_place(
      '22222222-2222-2222-2222-222222222222'::UUID,
      'node/67890'
    )$$,
    'Successful submission for needs_submission session (null next_turn)'
  );


-- ============================================================================
-- Test 3: Invalid session state (not in needs_submission)
-- ============================================================================
-- Create a session that is NOT in needs_submission state (has a question action)
INSERT INTO game_sessions (
  id,
  user_id,
  description,
  language_code,
  next_turn,
  status,
  was_correct
)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '00000000-0000-0000-0000-000000000001',
  'Active game session',
  'en',
  '{"action": "question", "question": "Is it in Europe?"}'::JSONB,
  'active',
  NULL
);


SELECT
  throws_ok(
    $$SELECT submit_place(
      '33333333-3333-3333-3333-333333333333'::UUID,
      'way/99999'
    )$$,
    'P0001',
    'submit_place failed: Session 33333333-3333-3333-3333-333333333333 is not in needs_submission state',
    'Throws error for session not in needs_submission state'
  );


-- ============================================================================
-- Test 4: Invalid ownership (session owned by different user)
-- ============================================================================
-- Create a session owned by a different user (bypass RLS to insert)
SET LOCAL role postgres;

INSERT INTO game_sessions (
  id,
  user_id,
  description,
  language_code,
  next_turn,
  status,
  was_correct
)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  '00000000-0000-0000-0000-000000000002', -- Different user
  'Other user session',
  'en',
  '{"action": "give_up"}'::JSONB,
  'active',
  NULL
);

-- Switch back to authenticated user
SET LOCAL role authenticated;


SELECT
  throws_ok(
    $$SELECT submit_place(
      '44444444-4444-4444-4444-444444444444'::UUID,
      'way/11111'
    )$$,
    'P0001',
    'submit_place failed: Not authorized to modify this session',
    'Throws error when session is owned by different user'
  );


-- ============================================================================
-- Test 5: Invalid osm_id (null)
-- ============================================================================
SELECT
  throws_ok(
    $$SELECT submit_place(
      '11111111-1111-1111-1111-111111111111'::UUID,
      NULL
    )$$,
    'P0001',
    'submit_place failed: OSM ID cannot be null or empty',
    'Throws error for null osm_id'
  );


-- ============================================================================
-- Test 6: Invalid osm_id (empty string)
-- ============================================================================
-- Create a fresh session for this test
INSERT INTO game_sessions (
  id,
  user_id,
  description,
  language_code,
  next_turn,
  status,
  was_correct
)
VALUES (
  '55555555-5555-5555-5555-555555555555',
  '00000000-0000-0000-0000-000000000001',
  'Empty osm_id test',
  'en',
  '{"action": "give_up"}'::JSONB,
  'active',
  NULL
);


SELECT
  throws_ok(
    $$SELECT submit_place(
      '55555555-5555-5555-5555-555555555555'::UUID,
      ''
    )$$,
    'P0001',
    'submit_place failed: OSM ID cannot be null or empty',
    'Throws error for empty osm_id'
  );


-- ============================================================================
-- Test 7: Session not found
-- ============================================================================
SELECT
  throws_ok(
    $$SELECT submit_place(
      '99999999-9999-9999-9999-999999999999'::UUID,
      'way/12345'
    )$$,
    'P0001',
    'submit_place failed: Session 99999999-9999-9999-9999-999999999999 not found',
    'Throws error for non-existent session'
  );


-- ============================================================================
-- Note on Rate Limiting
-- ============================================================================
-- Rate limiting is tested via game_logic.check_rate_limit which has a pgTAP
-- short-circuit that bypasses rate limiting in tests. The rate limiting
-- behavior is verified separately via integration tests.


-- ============================================================================
-- Test 8: Places RLS - Anonymous users can read places
-- ============================================================================
SET LOCAL role anon;
SELECT set_config('request.jwt.claim.role', 'anon', TRUE);
SELECT set_config('request.jwt.claim.sub', '', TRUE);

SELECT
  ok (
    (SELECT COUNT(*) FROM places) > 0,
    'Anonymous users can read places (RLS allows public read)'
  );


-- ============================================================================
-- Test 9: Places RLS - Anonymous users cannot insert places
-- ============================================================================
SELECT
  throws_ok (
    $sql$ INSERT INTO places (name, lat, lng) VALUES ('Hacker Place', 0, 0); $sql$,
    '42501',
    NULL,
    'Anonymous users cannot insert places (RLS blocks insert)'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
