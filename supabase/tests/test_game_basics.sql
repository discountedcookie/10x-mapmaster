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
  plan (4);


-- Test: Basic game flow with realistic descriptions
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
