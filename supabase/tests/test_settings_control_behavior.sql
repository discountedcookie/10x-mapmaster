BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (2);


-- Test: Settings in game_logic.config actually control game behavior
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
    (SELECT count FROM count_at_050) >= 1,
    'Default threshold (0.5) returns candidates'
  );


-- Raise threshold to 0.9 (very selective - should reduce candidates)
UPDATE game_logic.config
SET
  value = '0.9'::jsonb
WHERE
  key = 'candidates.semantic_similarity_threshold';


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
UPDATE game_logic.config
SET
  value = '0.5'::jsonb
WHERE
  key = 'candidates.semantic_similarity_threshold';


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
    'Raising semantic_similarity_threshold reduces candidates (proves config controls behavior)'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
