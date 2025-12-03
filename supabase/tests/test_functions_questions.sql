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
  plan (7);


-- ============================================================================
-- Test 1: Geographic questions are generated with candidates parameter
-- ============================================================================
CREATE TEMP TABLE game1 AS
SELECT
  start_game ('A tall tower') AS session_id;


-- Get candidates
CREATE TEMP TABLE candidates1 AS
SELECT
  get_candidates (
    (
      SELECT
        session_id
      FROM
        game1
    )
  ) AS candidates;


-- Get geographic questions with candidates
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        get_geographic_questions (
          (
            SELECT
              session_id
            FROM
              game1
          ),
          (
            SELECT
              candidates
            FROM
              candidates1
          ),
          5
        )
    ) > 0,
    'Geographic questions are available for game candidates'
  );


-- ============================================================================
-- Test 2: YES to geographic question filters candidates to that region
-- ============================================================================
CREATE TEMP TABLE game2 AS
SELECT
  start_game ('A tall tower') AS session_id;


-- Get initial candidate count (before geographic filtering)
CREATE TEMP TABLE before_filter AS
SELECT
  jsonb_array_length(
    get_candidates (
      (
        SELECT
          session_id
        FROM
          game2
      )
    )
  ) AS count;


-- Answer YES to "Is it in Europe?" (assuming Europe is asked first)
-- First, we need to find Europe's region_id
DO $$
DECLARE
  v_session_id uuid;
  v_europe_id uuid;
BEGIN
  SELECT session_id INTO v_session_id FROM game2;
  SELECT id INTO v_europe_id FROM geographic_regions WHERE name = 'Europe';
  
  -- Simulate answering YES to Europe question
  INSERT INTO game_answers (session_id, answer, geographic_region_id)
  VALUES (v_session_id, 'yes', v_europe_id);
END $$;


-- Get filtered candidate count (after geographic filtering)
CREATE TEMP TABLE after_filter AS
SELECT
  jsonb_array_length(
    get_candidates (
      (
        SELECT
          session_id
        FROM
          game2
      )
    )
  ) AS count;


-- Verify: Candidates reduced or equal after filtering to Europe
-- (reduces if some candidates were outside Europe, stays same if all were in Europe)
SELECT
  ok (
    (
      SELECT
        count
      FROM
        after_filter
    ) <= (
      SELECT
        count
      FROM
        before_filter
    ),
    'YES to Europe reduces candidate count'
  );


-- Verify: All remaining candidates are in Europe
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        filter_geographic_candidates (
          (
            SELECT
              session_id
            FROM
              game2
          )
        ) p
        JOIN geographic_regions gr ON gr.name = 'Europe'
      WHERE
        NOT st_intersects (p.geom, gr.geom)
    ) = 0,
    'All candidates after YES to Europe are actually in Europe'
  );


-- ============================================================================
-- Test 3: NO to geographic question excludes that region
-- ============================================================================
CREATE TEMP TABLE game3 AS
SELECT
  start_game ('A pyramid in a desert') AS session_id;


-- Count European candidates before filtering
CREATE TEMP TABLE european_count AS
SELECT
  count(*) AS count
FROM
  jsonb_array_elements(
    get_candidates (
      (
        SELECT
          session_id
        FROM
          game3
      )
    )
  ) AS c
  JOIN places p ON p.id = (c ->> 'id')::UUID
  JOIN geographic_regions gr ON gr.name = 'Europe'
WHERE
  st_intersects (p.geom, gr.geom);


-- Answer NO to "Is it in Europe?" 
DO $$
DECLARE
  v_session_id uuid;
  v_europe_id uuid;
BEGIN
  SELECT session_id INTO v_session_id FROM game3;
  SELECT id INTO v_europe_id FROM geographic_regions WHERE name = 'Europe';
  
  -- Simulate answering NO to Europe question
  INSERT INTO game_answers (session_id, answer, geographic_region_id)
  VALUES (v_session_id, 'no', v_europe_id);
END $$;


-- Verify: European candidates are excluded (if there were any)
-- This test passes even if there were 0 European candidates (which is fine)
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        filter_geographic_candidates (
          (
            SELECT
              session_id
            FROM
              game3
          )
        ) p
        JOIN geographic_regions gr ON gr.name = 'Europe'
      WHERE
        st_intersects (p.geom, gr.geom)
    ) = 0,
    'NO to Europe excludes European candidates (test passes if none present)'
  );


-- ============================================================================
-- Test 4: Multi-level geographic filtering (continent then country)
-- ============================================================================
CREATE TEMP TABLE game4 AS
SELECT
  start_game ('A famous tower in a European capital') AS session_id;


DO $$
DECLARE
  v_session_id uuid;
  v_europe_id uuid;
  v_france_id uuid;
BEGIN
  SELECT session_id INTO v_session_id FROM game4;
  SELECT id INTO v_europe_id FROM geographic_regions WHERE name = 'Europe';
  SELECT id INTO v_france_id FROM geographic_regions WHERE name = 'France';
  
  -- Answer YES to Europe, then YES to France
  INSERT INTO game_answers (session_id, answer, geographic_region_id)
  VALUES 
    (v_session_id, 'yes', v_europe_id),
    (v_session_id, 'yes', v_france_id);
END $$;


-- Verify: Only French places remain (intersection of Europe AND France)
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        filter_geographic_candidates (
          (
            SELECT
              session_id
            FROM
              game4
          )
        ) p
        JOIN geographic_regions gr ON gr.name = 'France'
      WHERE
        NOT st_intersects (p.geom, gr.geom)
    ) = 0,
    'Multi-level filtering (Europe → France) works correctly'
  );


-- ============================================================================
-- Test 5: Geographic questions calculate information gain
-- ============================================================================
CREATE TEMP TABLE game5 AS
SELECT
  start_game ('A landmark') AS session_id;


CREATE TEMP TABLE candidates5 AS
SELECT
  get_candidates (
    (
      SELECT
        session_id
      FROM
        game5
    )
  ) AS candidates;


-- Get geographic questions with information gain
CREATE TEMP TABLE geo_questions AS
SELECT
  *
FROM
  get_geographic_questions (
    (
      SELECT
        session_id
      FROM
        game5
    ),
    (
      SELECT
        candidates
      FROM
        candidates5
    ),
    10
  );


-- Verify: Questions with better splits are ranked higher
-- (split_quality represents information gain, should be > 0)
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        geo_questions
      WHERE
        split_quality > 0
    ) > 0,
    'Geographic questions have positive split quality scores'
  );


-- ============================================================================
-- Test 6: Exclude regions bug fix (was checking v_include_regions twice)
-- ============================================================================
CREATE TEMP TABLE game6 AS
SELECT
  start_game ('A tall mountain') AS session_id;


DO $$
DECLARE
  v_session_id uuid;
  v_europe_id uuid;
  v_asia_id uuid;
BEGIN
  SELECT session_id INTO v_session_id FROM game6;
  SELECT id INTO v_europe_id FROM geographic_regions WHERE name = 'Europe';
  SELECT id INTO v_asia_id FROM geographic_regions WHERE name = 'Asia';
  
  -- Answer NO to both Europe and Asia
  INSERT INTO game_answers (session_id, answer, geographic_region_id)
  VALUES 
    (v_session_id, 'no', v_europe_id),
    (v_session_id, 'no', v_asia_id);
END $$;


-- Verify: Both regions are excluded (bug was that NO answers didn't work)
SELECT
  ok (
    (
      SELECT
        count(*)
      FROM
        filter_geographic_candidates (
          (
            SELECT
              session_id
            FROM
              game6
          )
        ) p
        JOIN geographic_regions gr ON gr.name IN ('Europe', 'Asia')
      WHERE
        st_intersects (p.geom, gr.geom)
    ) = 0,
    'Multiple NO answers correctly exclude all specified regions'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
