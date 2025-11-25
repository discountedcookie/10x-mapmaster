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


SELECT
  pg_catalog.set_config ('search_path', 'public', FALSE);


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


-- HTTP requests for LLM API calls
CREATE EXTENSION if NOT EXISTS "pg_net"
WITH
  schema "extensions";


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
  schema "public";


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
  schema "public";


comment ON schema "public" IS 'standard public schema';


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
