BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (3);


-- ============================================================================
-- Schema Tests
-- ============================================================================
SELECT
  has_index (
    'game_logic',
    'geographic_regions',
    'idx_geographic_regions_geom',
    'GiST index exists on geographic_regions.geom'
  );


-- ============================================================================
-- RLS Tests
-- ============================================================================
SELECT
  ok (
    (
      SELECT
        relrowsecurity
      FROM
        pg_class
      WHERE
        relname = 'geographic_regions'
        AND relnamespace = 'game_logic'::regnamespace
    ),
    'RLS enabled on geographic_regions'
  );


-- Test: Geographic regions are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM game_logic.geographic_regions; $sql$,
    'Geographic regions are publicly readable'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
