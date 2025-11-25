BEGIN;


SET
  client_min_messages = warning;


SELECT
  plan (4);


-- Test: Basic game flow with realistic descriptions
-- Test 1: Specific description returns candidates
CREATE TEMP TABLE game1 AS
SELECT
  start_game ('A massive ancient temple complex in Cambodia') AS session_id;


SELECT
  ok (
    (
      SELECT
        count
      FROM
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


-- Test 2: Top candidate is correct
SELECT
  IS (
    (
      SELECT
        candidates -> 0 ->> 'name'
      FROM
        get_candidates (
          (
            SELECT
              session_id
            FROM
              game1
          )
        )
    ),
    'Angkor Wat',
    'Angkor Wat is top candidate for "ancient temple complex in Cambodia"'
  );


-- Test 3: System can match descriptions to places
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        places
      WHERE
        embedding_id IS NOT NULL
    ) > 40,
    'Most places have embeddings for semantic matching'
  );


-- Test 4: Embeddings are generated
SELECT
  ok (
    (
      SELECT
        description_embedding_id
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
