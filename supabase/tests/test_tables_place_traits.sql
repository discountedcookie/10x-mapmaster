BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (2);


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
        relname = 'place_traits'
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on place_traits'
  );


-- Test: Place traits are publicly readable
SELECT
  lives_ok (
    $sql$ SELECT COUNT(*) FROM place_traits; $sql$,
    'Place traits are publicly readable'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
