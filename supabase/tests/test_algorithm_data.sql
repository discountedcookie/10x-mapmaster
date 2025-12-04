BEGIN;


SET
  client_min_messages TO warning;


SET
  search_path = public,
  game_logic,
  extensions;


SET
  pgtap.version = '1.0';


SELECT
  plan (15);


-- ============================================================================
-- Test: filter_candidates_for_geography function
-- Uses real geographic_regions and places data
-- ============================================================================

-- Get a Europe region ID and some places for testing
DO $$
DECLARE
  v_europe_id UUID;
  v_asia_id UUID;
BEGIN
  SELECT id INTO v_europe_id FROM game_logic.geographic_regions WHERE name = 'Europe' AND level = 'continent';
  SELECT id INTO v_asia_id FROM game_logic.geographic_regions WHERE name = 'Asia' AND level = 'continent';
  
  PERFORM set_config('test.europe_id', v_europe_id::TEXT, TRUE);
  PERFORM set_config('test.asia_id', v_asia_id::TEXT, TRUE);
END $$;


-- Build test candidates JSONB from real places (mix of Europe and Asia)
CREATE TEMP TABLE test_candidates AS
WITH euro_places AS (
  SELECT p.id, p.name, ST_AsText(p.geom) as geom_wkt, 0.8 as confidence
  FROM places p
  JOIN game_logic.geographic_regions gr ON ST_Intersects(p.geom, gr.geom)
  WHERE gr.name = 'Europe' AND gr.level = 'continent'
  LIMIT 2
),
asia_places AS (
  SELECT p.id, p.name, ST_AsText(p.geom) as geom_wkt, 0.7 as confidence
  FROM places p
  JOIN game_logic.geographic_regions gr ON ST_Intersects(p.geom, gr.geom)
  WHERE gr.name = 'Asia' AND gr.level = 'continent'
  LIMIT 2
),
all_places AS (
  SELECT * FROM euro_places UNION ALL SELECT * FROM asia_places
)
SELECT jsonb_agg(
  jsonb_build_object(
    'id', id,
    'name', name,
    'geom_wkt', geom_wkt,
    'confidence', confidence
  )
) as candidates
FROM all_places;


-- Test 1: YES answer keeps only places inside region
SELECT
  ok (
    (
      SELECT jsonb_array_length(
        filter_candidates_for_geography(
          (SELECT candidates FROM test_candidates),
          current_setting('test.europe_id')::UUID,
          'yes'::answer_value
        )
      ) = 2  -- Only Europe places
    ),
    'geo_filter: YES keeps only places inside region (Europe)'
  );


-- Test 2: NO answer keeps only places outside region
SELECT
  ok (
    (
      SELECT jsonb_array_length(
        filter_candidates_for_geography(
          (SELECT candidates FROM test_candidates),
          current_setting('test.europe_id')::UUID,
          'no'::answer_value
        )
      ) = 2  -- Only non-Europe places (Asia)
    ),
    'geo_filter: NO keeps only places outside region'
  );


-- Test 3: NOT_SURE keeps all places
SELECT
  ok (
    (
      SELECT jsonb_array_length(
        filter_candidates_for_geography(
          (SELECT candidates FROM test_candidates),
          current_setting('test.europe_id')::UUID,
          'not_sure'::answer_value
        )
      ) = 4  -- All places
    ),
    'geo_filter: NOT_SURE keeps all places'
  );


-- Test 4: Empty candidates returns empty array
SELECT
  results_eq (
    $$SELECT filter_candidates_for_geography('[]'::JSONB, current_setting('test.europe_id')::UUID, 'yes'::answer_value)$$,
    $$SELECT '[]'::JSONB$$,
    'geo_filter: empty candidates returns empty array'
  );


-- Test 5: Invalid region raises exception
SELECT
  throws_ok (
    $$SELECT filter_candidates_for_geography('[{"id": "a", "geom_wkt": "POINT(0 0)"}]'::JSONB, '00000000-0000-0000-0000-000000000000'::UUID, 'yes'::answer_value)$$,
    'Geographic region 00000000-0000-0000-0000-000000000000 not found',
    'geo_filter: invalid region raises exception'
  );


-- Test 6: Filtered results preserve candidate data
SELECT
  ok (
    (
      SELECT (filtered->0->>'confidence')::FLOAT > 0
      FROM (
        SELECT filter_candidates_for_geography(
          (SELECT candidates FROM test_candidates),
          current_setting('test.europe_id')::UUID,
          'yes'::answer_value
        ) as filtered
      ) x
    ),
    'geo_filter: filtered results preserve confidence scores'
  );


-- ============================================================================
-- Test: adjust_candidates_for_answer function
-- Uses real traits and place_traits data
-- ============================================================================

-- Find a trait that some places have and some don't
DO $$
DECLARE
  v_trait_id UUID;
  v_place_with_trait UUID;
  v_place_without_trait UUID;
BEGIN
  -- Find a trait with limited places
  SELECT t.id INTO v_trait_id
  FROM traits t
  JOIN place_traits pt ON pt.trait_id = t.id
  GROUP BY t.id
  HAVING COUNT(*) BETWEEN 1 AND 10
  LIMIT 1;
  
  -- Find a place WITH this trait
  SELECT place_id INTO v_place_with_trait
  FROM place_traits
  WHERE trait_id = v_trait_id
  LIMIT 1;
  
  -- Find a place WITHOUT this trait
  SELECT p.id INTO v_place_without_trait
  FROM places p
  WHERE NOT EXISTS (
    SELECT 1 FROM place_traits pt 
    WHERE pt.place_id = p.id AND pt.trait_id = v_trait_id
  )
  LIMIT 1;
  
  PERFORM set_config('test.trait_id', v_trait_id::TEXT, TRUE);
  PERFORM set_config('test.place_with_trait', v_place_with_trait::TEXT, TRUE);
  PERFORM set_config('test.place_without_trait', v_place_without_trait::TEXT, TRUE);
END $$;


-- Test 7: NOT_SURE returns candidates unchanged
SELECT
  ok (
    (
      SELECT adjust_candidates_for_answer(
        '[{"id": "test", "confidence": 0.5}]'::JSONB,
        current_setting('test.trait_id')::UUID,
        'not_sure'::answer_value
      ) = '[{"id": "test", "confidence": 0.5}]'::JSONB
    ),
    'adjust: NOT_SURE returns candidates unchanged'
  );


-- Test 8: YES + has_trait boosts score
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_with_trait')::UUID, 'confidence', 0.5)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT > 0.5
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'yes'::answer_value
        ) as result
      ) x
    ),
    'adjust: YES + has_trait boosts score (>0.5)'
  );


-- Test 9: YES + !has_trait penalizes score
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_without_trait')::UUID, 'confidence', 0.5)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT < 0.5
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'yes'::answer_value
        ) as result
      ) x
    ),
    'adjust: YES + !has_trait penalizes score (<0.5)'
  );


-- Test 10: NO + has_trait penalizes score
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_with_trait')::UUID, 'confidence', 0.5)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT < 0.5
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'no'::answer_value
        ) as result
      ) x
    ),
    'adjust: NO + has_trait penalizes score (<0.5)'
  );


-- Test 11: NO + !has_trait boosts score
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_without_trait')::UUID, 'confidence', 0.5)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT > 0.5
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'no'::answer_value
        ) as result
      ) x
    ),
    'adjust: NO + !has_trait boosts score (>0.5)'
  );


-- Test 12: Score clamped to minimum 0.01
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_without_trait')::UUID, 'confidence', 0.01)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT >= 0.01
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'yes'::answer_value  -- penalty on already low score
        ) as result
      ) x
    ),
    'adjust: score clamped to minimum 0.01'
  );


-- Test 13: Score clamped to maximum 1.0
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_with_trait')::UUID, 'confidence', 0.99)
        ) as candidates
      )
      SELECT (result->0->>'confidence')::FLOAT <= 1.0
      FROM (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'yes'::answer_value  -- boost on already high score
        ) as result
      ) x
    ),
    'adjust: score clamped to maximum 1.0'
  );


-- Test 14: Empty candidates returns empty
SELECT
  results_eq (
    $$SELECT adjust_candidates_for_answer('[]'::JSONB, current_setting('test.trait_id')::UUID, 'yes'::answer_value)$$,
    $$SELECT '[]'::JSONB$$,
    'adjust: empty candidates returns empty array'
  );


-- Test 15: Multiple candidates adjusted independently
SELECT
  ok (
    (
      WITH test_data AS (
        SELECT jsonb_build_array(
          jsonb_build_object('id', current_setting('test.place_with_trait')::UUID, 'confidence', 0.5),
          jsonb_build_object('id', current_setting('test.place_without_trait')::UUID, 'confidence', 0.5)
        ) as candidates
      ),
      result AS (
        SELECT adjust_candidates_for_answer(
          (SELECT candidates FROM test_data),
          current_setting('test.trait_id')::UUID,
          'yes'::answer_value
        ) as adjusted
      )
      -- With YES answer: place_with_trait should be boosted, place_without_trait should be penalized
      -- So they should have different scores now
      SELECT (adjusted->0->>'confidence')::FLOAT != (adjusted->1->>'confidence')::FLOAT
      FROM result
    ),
    'adjust: multiple candidates adjusted independently'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
