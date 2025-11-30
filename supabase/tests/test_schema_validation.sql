BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (27);


-- ============================================================================
-- Schema Structure Tests
-- ============================================================================
-- Test 1: All required tables exist
SELECT
  has_table (
    'public',
    'geographic_regions',
    'geographic_regions table exists'
  );


SELECT
  has_table ('public', 'embeddings', 'embeddings table exists');


SELECT
  has_table ('public', 'places', 'places table exists');


SELECT
  has_table ('public', 'traits', 'traits table exists');


SELECT
  has_table (
    'public',
    'place_traits',
    'place_traits join table exists'
  );


SELECT
  has_table (
    'public',
    'game_sessions',
    'game_sessions table exists'
  );


SELECT
  has_table (
    'public',
    'game_answers',
    'game_answers table exists'
  );


SELECT
  has_table (
    'game_logic',
    'question_stats',
    'game_logic.question_stats table exists'
  );


SELECT
  has_table (
    'game_logic',
    'rate_limit_log',
    'game_logic.rate_limit_log table exists'
  );


-- Test 2: Config tables exist
SELECT
  has_table ('public', 'config', 'public.config table exists');


SELECT
  has_table (
    'game_logic',
    'config',
    'game_logic.config table exists'
  );


-- Test 3: Views exist
SELECT
  has_view (
    'public',
    'game_session_state',
    'game_session_state view exists'
  );


SELECT
  has_view ('public', 'user_stats', 'user_stats view exists');


SELECT
  has_view (
    'public',
    'global_stats',
    'global_stats view exists'
  );


-- Test 4: Custom types exist
SELECT
  has_type (
    'game_session_status',
    'game_session_status enum exists'
  );


SELECT
  has_type ('question_type', 'question_type enum exists');


SELECT
  has_type (
    'geographic_level',
    'geographic_level enum exists'
  );


SELECT
  has_type (
    'error_response',
    'error_response composite type exists'
  );


-- ============================================================================
-- Column Structure Tests
-- ============================================================================
-- Test 5: Key columns in game_sessions
SELECT
  col_has_default (
    'public',
    'game_sessions',
    'id',
    'game_sessions.id has default'
  );


SELECT
  col_not_null (
    'public',
    'game_sessions',
    'id',
    'game_sessions.id is not null'
  );


SELECT
  col_type_is (
    'public',
    'game_sessions',
    'description',
    'text',
    'game_sessions.description is text'
  );


-- Test 6: Foreign key constraints actually exist
SELECT
  fk_ok (
    'public',
    'game_sessions',
    'place_id',
    'public',
    'places',
    'id',
    'FK: game_sessions.place_id references places.id'
  );


SELECT
  fk_ok (
    'public',
    'game_answers',
    'session_id',
    'public',
    'game_sessions',
    'id',
    'FK: game_answers.session_id references game_sessions.id'
  );


-- ============================================================================
-- RLS Tests
-- ============================================================================
-- Test 7: RLS is enabled on all tables
SELECT
  row_security_is_enabled (
    'public',
    'game_sessions',
    'RLS enabled on game_sessions'
  );


SELECT
  row_security_is_enabled (
    'public',
    'game_answers',
    'RLS enabled on game_answers'
  );


SELECT
  row_security_is_enabled ('public', 'places', 'RLS enabled on places');


SELECT
  row_security_is_enabled (
    'public',
    'config',
    'RLS enabled on public.config'
  );


SELECT
  row_security_is_enabled (
    'game_logic',
    'config',
    'RLS enabled on game_logic.config'
  );


-- ============================================================================
-- Index Tests
-- ============================================================================
-- Test 8: Performance indexes exist
SELECT
  has_index (
    'public',
    'embeddings',
    'idx_embeddings_hnsw',
    'HNSW index exists on embeddings'
  );


SELECT
  has_index (
    'public',
    'places',
    'idx_places_geom_gist',
    'GiST index exists on places.geom'
  );


SELECT
  has_index (
    'public',
    'geographic_regions',
    'idx_geographic_regions_geom',
    'GiST index exists on geographic_regions.geom'
  );


-- ============================================================================
-- Configuration Tests
-- ============================================================================
-- Test 9: Critical config keys exist (functions depend on these)
SELECT
  ok (
    EXISTS (
      SELECT 1
      FROM
        game_logic.config
      WHERE
        key = 'scoring.initial_candidate_threshold'
    ),
    'Critical config key exists: scoring.initial_candidate_threshold'
  );


-- ============================================================================
-- Extension Tests
-- ============================================================================
-- Test 10: Required extensions are available
SELECT
  is_installed ('vector', 'pgvector extension is installed');


SELECT
  is_installed ('postgis', 'PostGIS extension is installed');


SELECT
  is_installed ('pgcrypto', 'pgcrypto extension is installed');


SELECT
  is_installed ('pg_cron', 'pg_cron extension is installed');


SELECT
  *
FROM
  finish ();


ROLLBACK;
