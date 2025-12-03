BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (1);


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
