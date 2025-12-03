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
    'embeddings',
    'idx_embeddings_hnsw',
    'HNSW index exists on embeddings'
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
        relname = 'embeddings'
        AND relnamespace = 'game_logic'::regnamespace
    ),
    'RLS enabled on embeddings'
  );


-- Test: Embeddings are restricted to service_role
SET
  local role authenticated;


SELECT
  set_config('request.jwt.claim.role', 'authenticated', TRUE);


SELECT
  set_config(
    'request.jwt.claim.sub',
    '550e8400-e29b-41d4-a716-446655440001',
    TRUE
  );


SELECT
  throws_ok (
    $sql$ SELECT COUNT(*) FROM game_logic.embeddings; $sql$,
    '42501',
    'permission denied for table embeddings',
    'Embeddings are restricted to service_role'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
