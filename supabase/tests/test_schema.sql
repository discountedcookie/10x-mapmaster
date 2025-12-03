-- ============================================
-- test_schema.sql
-- Tests for: Core database infrastructure
-- Extensions, custom types, triggers
-- ============================================
BEGIN;


SET
  client_min_messages = warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (8);


-- ============================================================================
-- Extension Tests
-- ============================================================================
-- Required extensions are available
SELECT
  ok (
    EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'vector'
    ),
    'pgvector extension is installed'
  );


SELECT
  ok (
    EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'postgis'
    ),
    'PostGIS extension is installed'
  );


SELECT
  ok (
    EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
    ),
    'pgcrypto extension is installed'
  );


SELECT
  ok (
    EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
    ),
    'pg_cron extension is installed'
  );


-- ============================================================================
-- Custom Type Tests
-- ============================================================================
-- Required enum and composite types exist
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


SELECT
  *
FROM
  finish ();


ROLLBACK;
