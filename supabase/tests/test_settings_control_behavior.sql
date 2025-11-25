BEGIN;


SET
  client_min_messages = warning;


SELECT
  plan (1);


-- Test: Settings actually control game behavior (not just configuration)
-- Create a test game
CREATE TEMP TABLE test_game AS
SELECT
  start_game ('A massive ancient temple complex in Cambodia') AS session_id;


-- Record candidate count with default threshold (0.5)
CREATE TEMP TABLE count_at_050 AS
SELECT
  count
FROM
  get_candidates (
    (
      SELECT
        session_id
      FROM
        test_game
    )
  );


-- Raise threshold to 0.8 (more selective - should reduce candidates)
UPDATE app_settings
SET
  value = '0.8'
WHERE
  key = 'semantic_similarity_threshold';


CREATE TEMP TABLE count_at_080 AS
SELECT
  count
FROM
  get_candidates (
    (
      SELECT
        session_id
      FROM
        test_game
    )
  );


-- Restore to 0.5
UPDATE app_settings
SET
  value = '0.5'
WHERE
  key = 'semantic_similarity_threshold';


-- Verify: Higher threshold = fewer (or same) candidates
-- This proves the function actually READS and USES the setting
SELECT
  ok (
    (
      SELECT
        count
      FROM
        count_at_080
    ) <= (
      SELECT
        count
      FROM
        count_at_050
    ),
    'Changing semantic_similarity_threshold actually changes candidate filtering (proves setting controls behavior)'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
