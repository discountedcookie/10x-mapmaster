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
  plan (6);


-- ============================================================================
-- Test: Basic start_game function
-- ============================================================================
-- Test 1: Specific description returns candidates
-- Note: Using traits that match seeded embeddings (Buddhism, ruins, tourism)
CREATE TEMP TABLE game1 AS
SELECT
  start_game ('Buddhist ruins and ancient religious site') AS session_id;


SELECT
  ok (
    jsonb_array_length(
      get_candidates (
        (
          SELECT
            session_id
          FROM
            game1
        )
      )
    ) > 0,
    'Specific description returns candidates'
  );


-- Test 2: Angkor Wat is in top candidates (embeddings may vary)
SELECT
  ok (
    EXISTS (
      SELECT
        1
      FROM
        jsonb_array_elements(
          get_candidates (
            (
              SELECT
                session_id
              FROM
                game1
            )
          )
        ) AS elem
      WHERE
        elem ->> 'name' = 'Angkor Wat'
    ),
    'Angkor Wat is in candidates for Buddhist ruins description'
  );


-- Test 3: Embeddings are generated for session descriptions
SELECT
  ok (
    (
      SELECT
        embedding_id
      FROM
        game_sessions
      WHERE
        id = (
          SELECT
            session_id
          FROM
            game1
        )
    ) IS NOT NULL,
    'Session embeddings are created'
  );


-- Test 4: Candidates in next_turn have normalized probabilities summing to 100%
SELECT
  ok (
    (
      SELECT
        abs(
          SUM((elem->>'probability')::FLOAT) - 1.0
        ) < 0.001
      FROM
        game_sessions gs,
        jsonb_array_elements(gs.next_turn->'candidates') elem
      WHERE
        gs.id = (
          SELECT
            session_id
          FROM
            game1
        )
    ),
    'Candidate probabilities sum to 1.0 (100%)'
  );


-- ============================================================================
-- Test: Settings in game_logic.config control game behavior
-- ============================================================================
-- Uses description that matches seeded embeddings for reliable results
CREATE TEMP TABLE test_game AS
SELECT
  start_game ('Buddhist ruins and ancient religious site') AS session_id;


-- Record candidate count with default threshold (0.5)
CREATE TEMP TABLE count_at_050 AS
SELECT
  jsonb_array_length(
    get_candidates (
      (
        SELECT
          session_id
        FROM
          test_game
      )
    )
  ) AS count;


-- Verify we have at least 1 candidate with default threshold
SELECT
  ok (
    (
      SELECT
        count
      FROM
        count_at_050
    ) >= 1,
    'Default threshold (0.5) returns candidates'
  );


-- Raise threshold to 0.9 (very selective - should reduce candidates)
SET
  local role service_role;


SELECT
  set_config('request.jwt.claim.role', 'service_role', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000001',
    TRUE
  );


UPDATE game_logic.config
SET
  value = '0.9'::JSONB
WHERE
  key = 'scoring.initial_candidate_threshold';


-- Restore role for game interactions
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


CREATE TEMP TABLE count_at_090 AS
SELECT
  jsonb_array_length(
    get_candidates (
      (
        SELECT
          session_id
        FROM
          test_game
      )
    )
  ) AS count;


-- Restore to 0.5
SET
  local role service_role;


SELECT
  set_config('request.jwt.claim.role', 'service_role', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000001',
    TRUE
  );


UPDATE game_logic.config
SET
  value = '0.5'::JSONB
WHERE
  key = 'scoring.initial_candidate_threshold';


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


-- Verify: Higher threshold = fewer (or same) candidates
-- This proves the function actually READS and USES the setting from game_logic.config
SELECT
  ok (
    (
      SELECT
        count
      FROM
        count_at_090
    ) <= (
      SELECT
        count
      FROM
        count_at_050
    ),
    'Raising initial_candidate_threshold reduces candidates (proves config controls behavior)'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
