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
-- Schema Tests
-- ============================================================================
SELECT
  has_table ('public', 'traits', 'traits table exists');


-- ============================================================================
-- RLS Tests
-- ============================================================================
-- Note: traits table inherits public read access from places domain
SELECT
  ok (
    (
      SELECT
        relrowsecurity
      FROM
        pg_class
      WHERE
        relname = 'traits'
        AND relnamespace = 'public'::regnamespace
    ),
    'RLS enabled on traits'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
