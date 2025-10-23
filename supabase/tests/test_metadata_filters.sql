-- supabase/tests/test_metadata_filters.sql
-- Comprehensive pgTAP tests for the apply_metadata_filter function

BEGIN;

-- Plan for the number of tests to run
SELECT plan(18);

-- Test Data & Filters
-- Simulating realistic JSONB objects for places and filters

-- Filters
-- 1. Bridge/Tower Filter
CREATE TEMP TABLE bridge_tower_filter AS SELECT '{"filter_type": "string_in_list_check", "property_paths": ["type"], "operator": "in", "value": ["bridge", "tower"]}'::jsonb AS f;
-- 2. Tall Feature Filter (>= 200m)
CREATE TEMP TABLE tall_filter AS SELECT '{"filter_type": "numeric_check", "property_paths": ["height_meters", "elevation_meters"], "operator": ">=", "value": [200]}'::jsonb AS f;
-- 3. Natural Feature Filter
CREATE TEMP TABLE natural_filter AS SELECT '{"filter_type": "string_in_list_check", "property_paths": ["class"], "operator": "in", "value": ["natural"]}'::jsonb AS f;
-- 4. Architect Exists Filter
CREATE TEMP TABLE architect_exists_filter AS SELECT '{"filter_type": "exists_check", "property_paths": ["extratags.architect"]}'::jsonb AS f;

-- Place Descriptors
-- 1. Tower (Eiffel)
CREATE TEMP TABLE place_tower AS SELECT '{"type": "tower", "class": "man_made", "height_meters": 330, "extratags": {"architect": "Gustave Eiffel"}}'::jsonb AS d;
-- 2. Lake (Geneva)
CREATE TEMP TABLE place_lake AS SELECT '{"type": "lake", "class": "natural"}'::jsonb AS d;
-- 3. Short Structure (Brandenburg Gate)
CREATE TEMP TABLE place_short_structure AS SELECT '{"type": "gate", "height_meters": 26}'::jsonb AS d;
-- 4. Tall Mountain (Everest)
CREATE TEMP TABLE place_tall_mountain AS SELECT '{"elevation_meters": 8848}'::jsonb AS d;
-- 5. Tall Mountain (Fuji)
CREATE TEMP TABLE place_tall_mountain_fuji AS SELECT '{"elevation_meters": 3776}'::jsonb AS d;
-- 6. Short Natural Feature (Statue of Liberty island)
CREATE TEMP TABLE place_short_natural AS SELECT '{"elevation_meters": 2}'::jsonb AS d;
-- 7. Fallback Test Place
CREATE TEMP TABLE place_fallback AS SELECT '{"height_meters": null, "elevation_meters": 2500}'::jsonb AS d;
-- 8. All Null Height/Elevation
CREATE TEMP TABLE place_all_null AS SELECT '{"type": "building"}'::jsonb AS d;
-- 9. Natural Feature (Grand Canyon)
CREATE TEMP TABLE place_natural AS SELECT '{"class": "natural"}'::jsonb AS d;
-- 10. Man-made without architect
CREATE TEMP TABLE place_no_architect AS SELECT '{"type": "building", "extratags": {}}'::jsonb AS d;


----------------------------------------------------------------
-- 1. Type Check Tests (string_in_list_check)
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM bridge_tower_filter), true),
  '[Type Check] Should PASS: Tower with answer=TRUE for bridge/tower filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_lake), (SELECT f FROM bridge_tower_filter), true),
  '[Type Check] Should FAIL: Lake with answer=TRUE for bridge/tower filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM bridge_tower_filter), false),
  '[Type Check] Should FAIL (Inverted): Tower with answer=FALSE for bridge/tower filter'
);

SELECT ok(
  apply_metadata_filter((SELECT d FROM place_lake), (SELECT f FROM bridge_tower_filter), false),
  '[Type Check] Should PASS (Inverted): Lake with answer=FALSE for bridge/tower filter'
);

----------------------------------------------------------------
-- 2. Numeric Check Tests (height_meters)
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM tall_filter), true),
  '[Numeric Check] Should PASS: Eiffel Tower (330m) with answer=TRUE for >=200m filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_short_structure), (SELECT f FROM tall_filter), true),
  '[Numeric Check] Should FAIL: Brandenburg Gate (26m) with answer=TRUE for >=200m filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM tall_filter), false),
  '[Numeric Check] Should FAIL (Inverted): Eiffel Tower (330m) with answer=FALSE for >=200m filter'
);

SELECT ok(
  apply_metadata_filter((SELECT d FROM place_short_structure), (SELECT f FROM tall_filter), false),
  '[Numeric Check] Should PASS (Inverted): Brandenburg Gate (26m) with answer=FALSE for >=200m filter'
);

----------------------------------------------------------------
-- 3. Numeric Check Tests with elevation_meters (Fallback)
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_tall_mountain), (SELECT f FROM tall_filter), true),
  '[Fallback] Should PASS: Mount Everest (8848m elevation) for >=200m filter'
);

SELECT ok(
  apply_metadata_filter((SELECT d FROM place_tall_mountain_fuji), (SELECT f FROM tall_filter), true),
  '[Fallback] Should PASS: Mount Fuji (3776m elevation) for >=200m filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_short_natural), (SELECT f FROM tall_filter), true),
  '[Fallback] Should FAIL: Statue of Liberty island (2m elevation) for >=200m filter'
);

----------------------------------------------------------------
-- 4. Property Path Fallback & NULL Handling
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_fallback), (SELECT f FROM tall_filter), true),
  '[Path Fallback] Should PASS: Uses elevation_meters (2500m) when height_meters is NULL'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_all_null), (SELECT f FROM tall_filter), true),
  '[NULL Handling] Should FAIL: Place with NULL height/elevation defaults to 0 and fails >=200m filter'
);

SELECT ok(
  apply_metadata_filter((SELECT d FROM place_all_null), (SELECT f FROM tall_filter), false),
  '[NULL Handling] Should PASS (Inverted): Place with NULL height/elevation passes when answer is FALSE'
);

----------------------------------------------------------------
-- 5. Natural Feature Test (string_in_list_check on 'class')
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_natural), (SELECT f FROM natural_filter), true),
  '[Natural Feature] Should PASS: Grand Canyon (class=natural) for natural feature filter'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM natural_filter), true),
  '[Natural Feature] Should FAIL: Eiffel Tower (class=man_made) for natural feature filter'
);

----------------------------------------------------------------
-- 6. Exists Check Test (New Filter Type)
----------------------------------------------------------------
SELECT ok(
  apply_metadata_filter((SELECT d FROM place_tower), (SELECT f FROM architect_exists_filter), true),
  '[Exists Check] Should PASS: Eiffel Tower has an architect property'
);

SELECT ok(
  NOT apply_metadata_filter((SELECT d FROM place_no_architect), (SELECT f FROM architect_exists_filter), true),
  '[Exists Check] Should FAIL: Place with no architect property fails exists check'
);


-- Finish the test plan
SELECT * FROM finish();

ROLLBACK;
