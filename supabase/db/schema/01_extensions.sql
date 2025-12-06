-- ============================================================================
-- PostgreSQL Extensions
-- ============================================================================
-- Description: All required PostgreSQL extensions for the application
-- Dependencies: None (must run first)
-- ============================================================================
SET
  statement_timeout = 0;


SET
  lock_timeout = 0;


SET
  idle_in_transaction_session_timeout = 0;


SET
  client_encoding = 'UTF8';


SET
  standard_conforming_strings = ON;


SET search_path TO public;


SET
  check_function_bodies = FALSE;


SET
  xmloption = content;


SET
  client_min_messages = error;


SET
  row_security = off;


-- Cron for scheduled jobs (session cleanup, question pruning)
CREATE EXTENSION if NOT EXISTS "pg_cron"
WITH
  schema "pg_catalog";


-- ============================================================================
-- Scheduled Maintenance Jobs
-- ============================================================================
-- Daily cleanup job at 2 AM UTC
SELECT
  cron.schedule (
    'daily-maintenance',
    '0 2 * * *', -- Every day at 2 AM UTC
    'SELECT game_logic.maintenance_cleanup();'
  );


-- Rate limit cleanup job every 30 minutes
SELECT
  cron.schedule (
    'rate-limit-cleanup',
    '*/30 * * * *', -- Every 30 minutes
    'DELETE FROM game_logic.rate_limit_log WHERE created_at < NOW() - INTERVAL ''1 hour'';'
  );


-- Backup processor for orphaned trait extraction jobs (every 60 seconds)
SELECT
  cron.schedule (
    'process-orphaned-trait-jobs',
    '* * * * *', -- Every minute
    'SELECT game_logic.process_orphaned_trait_jobs();'
  );


-- HTTP requests for LLM API calls
CREATE EXTENSION if NOT EXISTS "pg_net"
WITH
  schema "extensions";


-- Message queue for async job processing
-- Note: pgmq creates its own schema automatically
CREATE EXTENSION if NOT EXISTS "pgmq";


-- Initialize trait extraction queue
-- Used for async trait extraction after game completion
SELECT pgmq.create('trait_extraction');


-- Alternative HTTP extension for compatibility
CREATE EXTENSION if NOT EXISTS "http"
WITH
  schema "extensions";


-- GraphQL support
CREATE EXTENSION if NOT EXISTS "pg_graphql"
WITH
  schema "graphql";


-- Query statistics
CREATE EXTENSION if NOT EXISTS "pg_stat_statements"
WITH
  schema "extensions";


-- Password hashing (bcrypt for auth.users)
CREATE EXTENSION if NOT EXISTS "pgcrypto"
WITH
  schema "extensions";


-- Geographic data types and functions
CREATE EXTENSION if NOT EXISTS "postgis"
WITH
  schema "extensions";


-- Secrets management
CREATE EXTENSION if NOT EXISTS "supabase_vault"
WITH
  schema "vault";


-- UUID generation
CREATE EXTENSION if NOT EXISTS "uuid-ossp"
WITH
  schema "extensions";


-- Vector similarity search (pgvector)
CREATE EXTENSION if NOT EXISTS "vector"
WITH
  schema "extensions";


comment ON schema "public" IS 'standard public schema';

-- Reset search_path after extensions (some extensions modify it)
SET search_path TO public;

-- ============================================================================
-- Custom Types
-- ============================================================================
-- Description: Custom PostgreSQL types used across tables and views
-- ============================================================================
-- Game session status enum
-- Represents the lifecycle state of a game session
DROP TYPE if EXISTS game_session_status cascade;


CREATE TYPE game_session_status AS ENUM(
  'active', -- Game in progress, next_turn contains action
  'won', -- User guessed correctly
  'ended', -- Hit 5-turn limit without winning
  'needs_submission' -- Zero candidates, user must submit actual place
);


comment ON type game_session_status IS 'Game session lifecycle states:
- active: Game in progress (next_turn != NULL)
- won: User guessed correctly (was_correct = TRUE)
- ended: Hit turn limit without winning (was_correct = FALSE)
- needs_submission: Zero candidates, needs manual submission (next_turn = NULL, was_correct = NULL)';


-- Question type enum
-- Represents the type of question asked during gameplay
DROP TYPE if EXISTS question_type cascade;


CREATE TYPE question_type AS ENUM(
  'geographic', -- Geographic region filtering (bounding boxes)
  'semantic' -- Semantic similarity filtering (embeddings)
);


comment ON type question_type IS 'Question types used in the game:
- geographic: Filters candidates by geographic region (uses PostGIS bounding boxes)
- semantic: Filters candidates by semantic similarity (uses pgvector embeddings)';


-- Geographic level enum
-- Represents geographic granularity for region questions
DROP TYPE if EXISTS geographic_level cascade;


CREATE TYPE geographic_level AS ENUM(
  'continent', -- broadest level
  'region', -- subcontinent regions (e.g., Balkans, Southeast Asia)
  'country' -- most specific in our current model
);


comment ON type geographic_level IS 'Geographic hierarchy level for region questions. Comparison order defines specificity: continent < region < country';


-- Error response composite type
-- Standardized error response structure for RPC functions
DROP TYPE if EXISTS error_response cascade;


CREATE TYPE error_response AS (
  error_code TEXT,
  http_status INTEGER,
  details JSONB
);


comment ON type error_response IS 'Standardized error response for RPC functions:
- error_code: Machine-readable code for i18n translation lookup
- http_status: HTTP status code (400, 401, 403, 429, 500, etc.)
- details: Additional error context (optional)';


-- Answer value enum for game answers
DROP TYPE if EXISTS answer_value cascade;


CREATE TYPE answer_value AS ENUM('yes', 'no', 'not_sure');


comment ON type answer_value IS 'Valid answer values for game questions: yes, no, or not_sure';


-- ============================================================================
-- Additional Schemas
-- ============================================================================
-- Description: Schema organization for visibility and security boundaries
-- ============================================================================
-- Game logic schema for server-only functions and data
CREATE SCHEMA if NOT EXISTS game_logic;


comment ON schema game_logic IS 'Server-only game logic, functions, and private configuration. Not directly accessible to clients.';


-- Grant usage on game_logic schema
GRANT usage ON schema game_logic TO postgres,
authenticated,
anon,
service_role;
