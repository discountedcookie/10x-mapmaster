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
    'public',
    'places',
    'idx_places_geom_gist',
    'GiST index exists on places.geom'
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
        relname = 'places'
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on places'
  );


-- Test: Places are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM places; $sql$,
    'Places are publicly readable'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
