BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (4);


-- ============================================================================
-- Schema Tests
-- ============================================================================
SELECT
  has_table (
    'public',
    'geographic_regions',
    'geographic_regions table exists'
  );


SELECT
  has_index (
    'public',
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
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on geographic_regions'
  );


-- Test: Geographic regions are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM geographic_regions; $sql$,
    'Geographic regions are publicly readable'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
