-- Migration: Initial Schema and Functions
-- Generated: 2025-12-03T03:19:59.322Z
-- Mode: DEV (clean rebuild)
-- Schema: 1, Tables: 13, Functions: 63, Triggers: 1, Views: 4

-- ============================================================================
-- EXTENSIONS AND TYPES
-- ============================================================================

-- --------------------------------------------------------------------------
-- schema/01_extensions.sql
-- --------------------------------------------------------------------------

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

-- ============================================================================
-- TABLE DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- public/tables/embeddings.sql
-- --------------------------------------------------------------------------

-- Table: embeddings
-- Schema: public
-- Description: Stores text embeddings separately from entities for efficient querying
-- Spec: 384d vector per spec/overview.md and openspec/specs/database/spec.md
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."embeddings" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "source_text" "text" NOT NULL,
  "embedding" "extensions"."vector" (384) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."embeddings" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");


-- Indexes
-- HNSW index for fast approximate nearest neighbor search using cosine distance
-- Uses vector_cosine_ops to match the <=> cosine distance operator used in queries
CREATE INDEX if NOT EXISTS "idx_embeddings_hnsw" ON "public"."embeddings" USING hnsw ("embedding" extensions.vector_cosine_ops);


-- Unique constraint on source_text for deduplication
CREATE UNIQUE INDEX if NOT EXISTS "idx_embeddings_source_text" ON "public"."embeddings" ("source_text");


-- RLS Policies
ALTER TABLE "public"."embeddings" enable ROW level security;


DROP POLICY if EXISTS "Embeddings are viewable by everyone" ON "public"."embeddings";


DROP POLICY if EXISTS "Service role can manage embeddings" ON "public"."embeddings";


CREATE POLICY "Service role can manage embeddings" ON "public"."embeddings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Explicitly revoke read access from non-service roles; only service_role should see embeddings
REVOKE ALL ON public.embeddings
FROM
  public,
  anon,
  authenticated;


-- Comments
comment ON TABLE "public"."embeddings" IS 'Stores 384d text embeddings (gte-small compatible).';

-- --------------------------------------------------------------------------
-- public/tables/geographic_regions.sql
-- --------------------------------------------------------------------------

-- Table: geographic_regions
-- Schema: public
-- Description: Geographic regions (continents and countries) from Natural Earth
-- Used to generate geographic questions dynamically
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."geographic_regions" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "name" "text" NOT NULL,
  "level" "text" NOT NULL CHECK ("level" IN ('continent', 'country')),
  "geom" "extensions"."geometry" (multipolygon, 4326) NOT NULL,
  "continent_id" "uuid",
  "iso_code" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."geographic_regions" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."geographic_regions"
ADD CONSTRAINT "geographic_regions_pkey" PRIMARY KEY ("id");


-- Foreign Key (self-reference for continent hierarchy)
ALTER TABLE ONLY "public"."geographic_regions"
ADD CONSTRAINT "geographic_regions_continent_id_fkey" FOREIGN key ("continent_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_geographic_regions_level" ON "public"."geographic_regions" ("level");


CREATE INDEX if NOT EXISTS "idx_geographic_regions_geom" ON "public"."geographic_regions" USING gist ("geom");


CREATE INDEX if NOT EXISTS "idx_geographic_regions_continent_id" ON "public"."geographic_regions" ("continent_id");


-- RLS Policies
ALTER TABLE "public"."geographic_regions" enable ROW level security;


DROP POLICY if EXISTS "Geographic regions are viewable by everyone" ON "public"."geographic_regions";


DROP POLICY if EXISTS "Service role can manage geographic regions" ON "public"."geographic_regions";


CREATE POLICY "Geographic regions are viewable by everyone" ON "public"."geographic_regions" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage geographic regions" ON "public"."geographic_regions" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."geographic_regions" IS 'Geographic regions (continents and countries) from Natural Earth.
Used to generate geographic questions dynamically via v_geographic_questions view.
- level: continent or country
- continent_id: NULL for continents, references continent for countries
- iso_code: ISO 3166-1 alpha-2 code for countries (e.g., FR, JP)';

-- --------------------------------------------------------------------------
-- public/tables/traits.sql
-- --------------------------------------------------------------------------

-- Table: traits
-- Schema: public
-- Description: Canonical trait definitions used to describe and filter places
-- Spec: Each trait has id (UUID), clause (text), and embedding_id
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."traits" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "clause" TEXT NOT NULL,
  "embedding_id" UUID,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."traits" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."traits"
ADD CONSTRAINT "traits_pkey" PRIMARY KEY ("id");


-- Foreign Key
ALTER TABLE ONLY "public"."traits"
ADD CONSTRAINT "traits_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE UNIQUE INDEX if NOT EXISTS "idx_traits_embedding_id" ON "public"."traits" ("embedding_id");


-- RLS Policies
ALTER TABLE "public"."traits" enable ROW level security;


DROP POLICY if EXISTS "Traits viewable by everyone" ON "public"."traits";


DROP POLICY if EXISTS "Service role can manage traits" ON "public"."traits";


CREATE POLICY "Traits viewable by everyone" ON "public"."traits" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage traits" ON "public"."traits" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."traits" IS 'Canonical trait vocabulary per spec. Each trait has id, clause (text), and embedding_id for semantic similarity calculations.';

-- --------------------------------------------------------------------------
-- public/tables/places.sql
-- --------------------------------------------------------------------------

-- Table: places
-- Schema: public
-- Description: Stores geographic locations with trait-based descriptions
-- Geometry accepts Point, Polygon, or MultiPolygon from Nominatim
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."places" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "name" "text" NOT NULL,
  "osm_id" "text" NOT NULL,
  "lat" DOUBLE PRECISION,
  "lng" DOUBLE PRECISION,
  "geom" "extensions"."geometry" (geometry, 4326),
  "embedding_id" "uuid",
  "times_encountered" INTEGER DEFAULT 0 NOT NULL,
  "pending_review" BOOLEAN DEFAULT FALSE NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."places" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_pkey" PRIMARY KEY ("id");


-- Unique Constraint
ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_osm_id_key" UNIQUE ("osm_id");


-- Foreign Key
ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_places_embedding_id" ON "public"."places" ("embedding_id");


CREATE INDEX if NOT EXISTS "idx_places_geom_gist" ON "public"."places" USING gist ("geom");


CREATE INDEX if NOT EXISTS "idx_places_name" ON "public"."places" ("name");


-- RLS Policies
ALTER TABLE "public"."places" enable ROW level security;


DROP POLICY if EXISTS "Places are viewable by everyone" ON "public"."places";


DROP POLICY if EXISTS "Service role can insert places" ON "public"."places";


DROP POLICY if EXISTS "Service role can update places" ON "public"."places";


CREATE POLICY "Places are viewable by everyone" ON "public"."places" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can insert places" ON "public"."places" FOR insert
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


CREATE POLICY "Service role can update places" ON "public"."places"
FOR UPDATE
  USING (("auth"."role" () = 'service_role'::"text"));


-- NOTE: "Users can delete their own places" policy is in rls_deferred.sql
-- because it references game_sessions which depends on places
-- Comments
comment ON TABLE "public"."places" IS 'Geographic locations with trait-based descriptions and embeddings.';

-- --------------------------------------------------------------------------
-- public/tables/game_sessions.sql
-- --------------------------------------------------------------------------

-- Table: game_sessions
-- Schema: public
-- Description: Tracks active and completed game sessions with trait-based state
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."game_sessions" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid",
  "place_id" "uuid",
  "was_correct" BOOLEAN,
  "description" "text" NOT NULL CHECK (
    length(trim("description")) > 0
    AND length("description") <= 200
  ),
  "language_code" "text" DEFAULT 'en'::"text" NOT NULL,
  "embedding_id" UUID,
  "status" "game_session_status" DEFAULT 'active'::"game_session_status" NOT NULL,
  "pending_review" BOOLEAN DEFAULT FALSE NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "next_turn" "jsonb"
);


ALTER TABLE "public"."game_sessions" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id");


-- Foreign Keys
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_game_sessions_user_id" ON "public"."game_sessions" ("user_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_place_id" ON "public"."game_sessions" ("place_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_created_at" ON "public"."game_sessions" ("created_at");


CREATE INDEX if NOT EXISTS "idx_game_sessions_status" ON "public"."game_sessions" ("status");


-- RLS Policies
ALTER TABLE "public"."game_sessions" enable ROW level security;


ALTER TABLE "public"."game_sessions" force ROW level security;


DROP POLICY if EXISTS "Users can view their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can insert their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can update their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can delete their own game sessions" ON "public"."game_sessions";


CREATE POLICY "Users can view their own game sessions" ON "public"."game_sessions" FOR
SELECT
  USING (
    ("auth"."uid" () = "user_id")
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can insert their own game sessions" ON "public"."game_sessions" FOR insert
WITH
  CHECK (
    (
      (
        "auth"."uid" () IS NOT NULL
        AND "auth"."uid" () = "user_id"
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can update their own game sessions" ON "public"."game_sessions"
FOR UPDATE
  USING (
    ("auth"."uid" () = "user_id")
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can delete their own game sessions" ON "public"."game_sessions" FOR delete USING (
  ("auth"."uid" () = "user_id")
  OR ("auth"."role" () = 'service_role'::"text")
);


-- Comments
comment ON COLUMN "public"."game_sessions"."next_turn" IS 'Cached next turn for the game session. Stores one of:
- {"action": "question", "question_id": "uuid", "question_text": "...", "candidates": [...]}
- {"action": "guess", "place_id": "uuid", "place_name": "...", "candidates": [...]}
- {"action": "give_up", "reason": "no_candidates"}
- NULL (session won/lost - check was_correct)';


-- Note: Triggers defined in schema/triggers.sql (loaded after functions)

-- --------------------------------------------------------------------------
-- public/tables/game_answers.sql
-- --------------------------------------------------------------------------

-- Table: game_answers
-- Schema: public
-- Description: Records each answer (question response or wrong guess) during a game session
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."game_answers" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "session_id" "uuid" NOT NULL,
  "trait_id" UUID,
  "geographic_region_id" "uuid",
  "answer" answer_value NOT NULL,
  "place_id" "uuid",
  "candidates" "jsonb",
  "question_text" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."game_answers" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_pkey" PRIMARY KEY ("id");


-- Polymorphic constraint: exactly one of trait_id, geographic_region_id, place_id must be set
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_polymorphic_check" CHECK (
  num_nonnulls (trait_id, geographic_region_id, place_id) = 1
);


-- Foreign Keys
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_session_id_fkey" FOREIGN key ("session_id") REFERENCES "public"."game_sessions" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_game_answers_session_id" ON "public"."game_answers" ("session_id");


CREATE INDEX if NOT EXISTS "idx_game_answers_polymorphic" ON "public"."game_answers" (trait_id, geographic_region_id, place_id);


-- RLS Policies
ALTER TABLE "public"."game_answers" enable ROW level security;


ALTER TABLE "public"."game_answers" force ROW level security;


DROP POLICY if EXISTS "Users can insert answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can update answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can view answers for their sessions" ON "public"."game_answers";


CREATE POLICY "Users can view answers for their sessions" ON "public"."game_answers" FOR
SELECT
  USING (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can insert answers for their sessions" ON "public"."game_answers" FOR insert
WITH
  CHECK (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can update answers for their sessions" ON "public"."game_answers"
FOR UPDATE
  USING (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


-- Comments
comment ON TABLE "public"."game_answers" IS 'Records player answers. Questions are generated from trait_id or geographic_region_id, not stored.';

-- --------------------------------------------------------------------------
-- game_logic/tables/config.sql
-- --------------------------------------------------------------------------

-- Table: config
-- Schema: game_logic
-- Description: Server-only configuration settings for game logic
-- Table Definition
CREATE TABLE IF NOT EXISTS "game_logic"."config" (
  "key" "text" NOT NULL,
  "value" "jsonb" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "game_logic"."config" owner TO "postgres";


-- RLS Policies
ALTER TABLE "game_logic"."config" enable ROW level security;


ALTER TABLE "game_logic"."config" force ROW level security;


DROP POLICY if EXISTS "Service role can manage game_logic config" ON "game_logic"."config";


CREATE POLICY "Service role can manage game_logic config" ON "game_logic"."config" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Grant access to service role
GRANT usage ON schema game_logic TO service_role;


GRANT
SELECT
,
  insert,
UPDATE,
delete ON TABLE game_logic.config TO service_role;


-- Comments
comment ON TABLE "game_logic"."config" IS 'Server-only configuration settings for game logic (e.g., scoring.temperature, confidence thresholds)';


comment ON COLUMN "game_logic"."config"."key" IS 'Configuration key (e.g., scoring.temperature)';


comment ON COLUMN "game_logic"."config"."value" IS 'Configuration value as JSON';


comment ON COLUMN "game_logic"."config"."description" IS 'Human-readable description of the setting';

-- --------------------------------------------------------------------------
-- game_logic/tables/question_stats.sql
-- --------------------------------------------------------------------------

-- Table: question_stats
-- Schema: game_logic
-- Description: Tracks effectiveness of questions (internal analytics)
CREATE TABLE IF NOT EXISTS "game_logic"."question_stats" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "question_type" "public"."question_type" NOT NULL,
  "trait_id" UUID,
  "geographic_region_id" "uuid",
  "times_asked" INTEGER DEFAULT 0 NOT NULL,
  "effectiveness_score" DOUBLE PRECISION DEFAULT 0.5 NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  CONSTRAINT "question_stats_type_check" CHECK (
    (
      "question_type" = 'geographic'
      AND "geographic_region_id" IS NOT NULL
      AND "trait_id" IS NULL
    )
    OR (
      "question_type" = 'semantic'
      AND "trait_id" IS NOT NULL
      AND "geographic_region_id" IS NULL
    )
  )
);


ALTER TABLE "game_logic"."question_stats" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "game_logic"."question_stats"
ADD CONSTRAINT "question_stats_pkey" PRIMARY KEY ("id");


-- Foreign Keys
ALTER TABLE ONLY "game_logic"."question_stats"
ADD CONSTRAINT "question_stats_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "game_logic"."question_stats"
ADD CONSTRAINT "question_stats_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_question_stats_trait_id" ON "game_logic"."question_stats" ("trait_id");


CREATE INDEX if NOT EXISTS "idx_question_stats_geographic_region_id" ON "game_logic"."question_stats" ("geographic_region_id");


CREATE INDEX if NOT EXISTS "idx_question_stats_effectiveness" ON "game_logic"."question_stats" ("effectiveness_score" DESC);


-- RLS Policies
ALTER TABLE "game_logic"."question_stats" enable ROW level security;


DROP POLICY if EXISTS "Service role can manage question stats" ON "game_logic"."question_stats";


CREATE POLICY "Service role can manage question stats" ON "game_logic"."question_stats" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Table Grants
GRANT
SELECT
,
  insert,
UPDATE,
delete ON "game_logic"."question_stats" TO service_role;


-- Comments
comment ON TABLE "game_logic"."question_stats" IS 'Internal: Tracks question effectiveness for algorithm tuning.';

-- --------------------------------------------------------------------------
-- game_logic/tables/rate_limit_log.sql
-- --------------------------------------------------------------------------

-- Table: rate_limit_log
-- Schema: game_logic
-- Description: Tracks rate limit requests for enforcement and analytics (internal)
CREATE TABLE IF NOT EXISTS "game_logic"."rate_limit_log" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid" NOT NULL,
  "action" "text" NOT NULL,
  "ip_address" "inet",
  "user_agent" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "game_logic"."rate_limit_log" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "game_logic"."rate_limit_log"
ADD CONSTRAINT "rate_limit_log_pkey" PRIMARY KEY ("id");


-- Indexes
CREATE INDEX if NOT EXISTS "idx_rate_limit_log_user_id" ON "game_logic"."rate_limit_log" ("user_id");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_created_at" ON "game_logic"."rate_limit_log" ("created_at");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_action" ON "game_logic"."rate_limit_log" ("action");


-- RLS Policies
ALTER TABLE "game_logic"."rate_limit_log" enable ROW level security;


ALTER TABLE "game_logic"."rate_limit_log" force ROW level security;


DROP POLICY if EXISTS "Service role can manage rate limit log" ON "game_logic"."rate_limit_log";


CREATE POLICY "Service role can manage rate limit log" ON "game_logic"."rate_limit_log" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Table Grants (required before RLS policies can be evaluated)
GRANT
SELECT
,
  insert,
UPDATE,
delete ON "game_logic"."rate_limit_log" TO service_role;


GRANT
SELECT
,
  insert,
UPDATE,
delete ON "game_logic"."rate_limit_log" TO postgres;


-- Comments
comment ON TABLE "game_logic"."rate_limit_log" IS 'Internal: Tracks rate limit requests. Cleaned up by pg_cron.';


comment ON COLUMN "game_logic"."rate_limit_log"."action" IS 'Action being rate limited (e.g., start_game, play_turn)';

-- --------------------------------------------------------------------------
-- public/tables/app_settings.sql
-- --------------------------------------------------------------------------

-- Table: app_settings
-- Schema: public
-- Description: Stores application configuration including LLM prompts
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."app_settings" (
  "key" "text" NOT NULL,
  "value" "text" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "public"."app_settings" owner TO "postgres";


-- RLS Policies
ALTER TABLE "public"."app_settings" enable ROW level security;


DROP POLICY if EXISTS "App settings are readable by everyone" ON "public"."app_settings";


DROP POLICY if EXISTS "Service role can manage app settings" ON "public"."app_settings";


CREATE POLICY "App settings are readable by everyone" ON "public"."app_settings" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage app settings" ON "public"."app_settings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."app_settings" IS 'Application configuration settings including LLM system prompts';


comment ON COLUMN "public"."app_settings"."key" IS 'Configuration key (e.g., question_generation_system_prompt)';


comment ON COLUMN "public"."app_settings"."value" IS 'Configuration value (e.g., system prompt text)';


comment ON COLUMN "public"."app_settings"."description" IS 'Human-readable description of the setting';

-- --------------------------------------------------------------------------
-- public/tables/config.sql
-- --------------------------------------------------------------------------

-- Table: config
-- Schema: public
-- Description: Client-visible configuration settings
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."config" (
  "key" "text" NOT NULL,
  "value" "jsonb" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "public"."config" owner TO "postgres";


-- RLS Policies
ALTER TABLE "public"."config" enable ROW level security;


DROP POLICY if EXISTS "Public config is readable by everyone" ON "public"."config";


DROP POLICY if EXISTS "Service role can manage public config" ON "public"."config";


CREATE POLICY "Public config is readable by everyone" ON "public"."config" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage public config" ON "public"."config" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."config" IS 'Client-visible configuration settings (e.g., game.max_turns)';


comment ON COLUMN "public"."config"."key" IS 'Configuration key (e.g., game.max_turns)';


comment ON COLUMN "public"."config"."value" IS 'Configuration value as JSON';


comment ON COLUMN "public"."config"."description" IS 'Human-readable description of the setting';

-- --------------------------------------------------------------------------
-- public/tables/zz_place_traits.sql
-- --------------------------------------------------------------------------

-- Table: place_traits
-- Schema: public
-- Description: Links places to traits
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."place_traits" (
  "place_id" UUID NOT NULL,
  "trait_id" UUID NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."place_traits" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."place_traits"
ADD CONSTRAINT "place_traits_pkey" PRIMARY KEY ("place_id", "trait_id");


-- Foreign Keys
ALTER TABLE ONLY "public"."place_traits"
ADD CONSTRAINT "place_traits_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."place_traits"
ADD CONSTRAINT "place_traits_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."traits" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_place_traits_trait_id" ON "public"."place_traits" ("trait_id");


-- RLS Policies
ALTER TABLE "public"."place_traits" enable ROW level security;


DROP POLICY if EXISTS "Place traits viewable by everyone" ON "public"."place_traits";


DROP POLICY if EXISTS "Service role can manage place traits" ON "public"."place_traits";


CREATE POLICY "Place traits viewable by everyone" ON "public"."place_traits" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place traits" ON "public"."place_traits" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."place_traits" IS 'Associates places with traits.';

-- --------------------------------------------------------------------------
-- public/tables/zz_rls_deferred.sql
-- --------------------------------------------------------------------------

-- Deferred RLS Policies
-- Schema: public
-- Description: RLS policies that reference tables with circular dependencies
-- These policies must be created after ALL tables exist
-- Places: Users can delete their own places (depends on game_sessions)
DROP POLICY if EXISTS "Users can delete their own places" ON "public"."places";


CREATE POLICY "Users can delete their own places" ON "public"."places" FOR delete USING (
  (
    "id" IN (
      SELECT
        "game_sessions"."place_id"
      FROM
        "public"."game_sessions"
      WHERE
        ("game_sessions"."user_id" = "auth"."uid" ())
    )
  )
  OR ("auth"."role" () = 'service_role'::"text")
);

-- ============================================================================
-- FUNCTION DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- public/functions/play_turn.sql
-- --------------------------------------------------------------------------

-- Function: play_turn
-- Category: game
-- Purpose: Route turn processing to appropriate handler (SRP - Router pattern)
-- REFACTORED: Extracted handlers for SRP and OCP compliance
CREATE OR REPLACE FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session_record RECORD;
BEGIN
  -- Require authenticated (including Supabase anonymous) session
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- ============================================================================
  -- RATE LIMITING
  -- ============================================================================
  -- Enforces limits from game_logic.config (default: 60 per minute)
  PERFORM game_logic.check_rate_limit('play_turn');

  -- ============================================================================
  -- VALIDATION & SESSION RETRIEVAL
  -- ============================================================================
  
  IF p_session_id IS NULL OR p_answer IS NULL THEN
    RAISE EXCEPTION 'Parameters cannot be null';
  END IF;

  -- Get session details (only columns needed by handlers)
  SELECT
    id,
    user_id,
    place_id,
    was_correct,
    next_turn,
    description,
    embedding_id
  INTO v_session_record
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;

  -- Ownership check (service_role may bypass)
  IF auth.role() <> 'service_role' AND (v_session_record.user_id IS NULL OR v_session_record.user_id != auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized to modify this session';
  END IF;

  -- Validate session is active
  IF v_session_record.was_correct = TRUE THEN
    RAISE EXCEPTION 'Session % is already won', p_session_id;
  END IF;
  
  IF v_session_record.next_turn IS NULL THEN
    RAISE EXCEPTION 'Session % has no active turn', p_session_id;
  END IF;

  -- ============================================================================
  -- ROUTE TO APPROPRIATE HANDLER (SRP)
  -- ============================================================================

  IF v_session_record.next_turn->>'action' = 'guess' THEN
    PERFORM handle_guess(p_answer, v_session_record);
  ELSIF v_session_record.next_turn->>'action' = 'question' THEN
    PERFORM handle_question(p_answer, v_session_record);
  ELSE
    RAISE EXCEPTION 'Unknown action type: %', v_session_record.next_turn->>'action';
  END IF;
END;
$$;


ALTER FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) owner TO "postgres";


comment ON function "public"."play_turn" ("p_session_id" "uuid", "p_answer" answer_value) IS 'Router function for processing game turns (SRP pattern).

Responsibilities:
- Validate session state
- Route to appropriate handler based on action type:
  * guess → handle_guess()
  * question → handle_question()

SOLID principles:
- SRP: Each handler has single responsibility
- OCP: New action types can be added without modifying existing handlers
- DIP: Depends on abstractions (handler functions)

Returns: VOID (raises exception on error)
Frontend fetches full game state from game_session_state view after call.';

-- --------------------------------------------------------------------------
-- public/functions/start_game.sql
-- --------------------------------------------------------------------------

-- Function: start_game
-- Category: game
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."start_game" (
  "p_description" "text",
  "p_language_code" "text" DEFAULT 'en'
) returns UUID language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session_id uuid;
  v_candidates jsonb;
  v_embedding_id uuid;
BEGIN
  -- Require authenticated (including Supabase anonymous) session
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Rate limiting via centralized check_rate_limit function
  -- Enforces limits from game_logic.config (default: 10 per minute)
  PERFORM game_logic.check_rate_limit('start_game');

  -- Generate description embedding first
  v_embedding_id := get_embedding(p_description);
  
  -- Insert session with description embedding
  INSERT INTO game_sessions (
    user_id,
    description,
    language_code,
    embedding_id
  )
  VALUES (
    auth.uid(),
    p_description,
    p_language_code,
    v_embedding_id
  )
  RETURNING id INTO v_session_id;

  -- Get candidates
  v_candidates := get_candidates(v_session_id);

  -- Decide next turn
  PERFORM decide_next_turn(v_session_id, v_candidates);
  
  RETURN v_session_id;
END;
$$;


ALTER FUNCTION "public"."start_game" ("p_description" "text", "p_language_code" "text") owner TO "postgres";


comment ON function "public"."start_game" ("p_description" "text", "p_language_code" "text") IS 'Starts a new game session with server-side embedding generation.

Parameters:
- p_description: User description of the place (max 500 chars)
- p_language_code: Language code (default: en)

Returns: session_id only. Frontend fetches full game state (including next_turn) from game_session_state view.

Process:
1. Generates embedding for description
2. Creates session in database
3. Calls decide_next_turn() to build initial next_turn JSONB with candidates

Security: Uses auth.uid() internally - no user_id parameter needed.

CONSERVATIVE GUESS POLICY:
- Guess when: (candidate_count = 1) OR (candidate_count <= 2 AND top_confidence >= 0.90 AND confidence_gap >= 0.15)
- Guard: If candidate_count <= 3 at start, force a guess (no questions needed)';

-- --------------------------------------------------------------------------
-- public/functions/submit_place.sql
-- --------------------------------------------------------------------------

-- Function: submit_place
-- Category: game
-- Purpose: Submit the correct place after game gives up
-- Spec: openspec/specs/database/spec.md#submit_place
CREATE OR REPLACE FUNCTION "public"."submit_place" ("p_session_id" UUID, "p_osm_id" TEXT) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_session RECORD;
  v_nominatim_data JSONB;
  v_traits JSONB;
  v_place_id UUID;
  v_is_registered BOOLEAN;
  v_pending_review BOOLEAN;
BEGIN
  -- ============================================================================
  -- AUTHENTICATION CHECK
  -- ============================================================================
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to submit a place';
  END IF;

  -- ============================================================================
  -- RATE LIMITING
  -- ============================================================================
  PERFORM game_logic.check_rate_limit('submit_place');

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_session_id IS NULL THEN
    RAISE EXCEPTION 'Session ID cannot be null';
  END IF;
  
  IF p_osm_id IS NULL OR trim(p_osm_id) = '' THEN
    RAISE EXCEPTION 'OSM ID cannot be null or empty';
  END IF;

  -- ============================================================================
  -- SESSION VALIDATION & OWNERSHIP CHECK
  -- ============================================================================
  SELECT id, user_id, was_correct, next_turn, description
  INTO v_session
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;

  IF v_session.user_id IS NOT NULL AND v_session.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to modify this session';
  END IF;

  -- Verify session is in 'needs_submission' state (game ended without winning)
  IF NOT (
    (v_session.next_turn->>'action' = 'give_up') OR
    (v_session.next_turn IS NULL AND v_session.was_correct IS NOT TRUE)
  ) THEN
    RAISE EXCEPTION 'Session % is not in needs_submission state', p_session_id;
  END IF;

  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    UPDATE game_sessions
    SET 
      was_correct = FALSE,
      next_turn = NULL,
      pending_review = TRUE
    WHERE id = p_session_id;
    RETURN;
  END IF;

  -- ============================================================================
  -- DETERMINE USER TYPE
  -- ============================================================================
  SELECT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email IS NOT NULL 
    AND email != ''
  ) INTO v_is_registered;

  v_pending_review := NOT v_is_registered;

  -- ============================================================================
  -- FETCH, EXTRACT, CREATE (using helper functions)
  -- ============================================================================
  v_nominatim_data := game_logic.fetch_nominatim_place(p_osm_id);
  v_traits := game_logic.extract_traits_from_nominatim(v_nominatim_data);
  v_place_id := game_logic.create_place_with_traits(p_osm_id, v_nominatim_data, v_traits, FALSE);

  -- ============================================================================
  -- UPDATE SESSION
  -- ============================================================================
  UPDATE game_sessions
  SET 
    place_id = v_place_id,
    was_correct = FALSE,
    next_turn = NULL,
    status = 'ended',
    pending_review = v_pending_review,
    user_id = COALESCE(user_id, auth.uid())
  WHERE id = p_session_id;

  -- ============================================================================
  -- IF REGISTERED USER, UPDATE TRAITS
  -- ============================================================================
  IF NOT v_pending_review THEN
    PERFORM game_logic.update_place_traits(v_place_id);
  END IF;

  RETURN;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'submit_place failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."submit_place" (UUID, TEXT) owner TO "postgres";


comment ON function "public"."submit_place" (UUID, TEXT) IS 'Submit the correct place after game gives up.

Parameters:
- p_session_id: The game session ID
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364")

Process:
1. Validate auth and session ownership
2. Verify session is in needs_submission state
3. Fetch place data from Nominatim
4. Extract traits (LLM + rule-based)
5. Create place with traits and embedding
6. Link session to place

Security: SECURITY DEFINER. Uses auth.uid() for ownership validation.';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/adjust_candidates_for_answer.sql
-- --------------------------------------------------------------------------

-- Function: adjust_candidates_for_answer
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Adjust all candidate scores based on a semantic answer using binary trait matching
-- Spec: docs/architecture/algorithm.md#trait-matching
CREATE OR REPLACE FUNCTION "game_logic"."adjust_candidates_for_answer" (
  p_candidates JSONB,
  p_trait_id UUID,
  p_answer answer_value
) returns JSONB language plpgsql
SET
  search_path = public,
  extensions,
  game_logic AS $$
DECLARE
  v_candidate JSONB;
  v_place_id UUID;
  v_current_score FLOAT;
  v_new_score FLOAT;
  v_has_trait BOOLEAN;
  v_boost_factor FLOAT;
  v_penalty_factor FLOAT;
  v_multiplier FLOAT;
  v_result JSONB := '[]'::JSONB;
BEGIN
  -- Not sure = return unchanged candidates
  IF p_answer = 'not_sure' THEN
    RETURN p_candidates;
  END IF;
  
  -- Get config values
  v_boost_factor := get_config_float('traits.boost_factor', 1.5);
  v_penalty_factor := get_config_float('traits.penalty_factor', 0.6);
  
  -- Process each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_place_id := (v_candidate->>'id')::UUID;
    v_current_score := COALESCE((v_candidate->>'confidence')::FLOAT, 0.5);
    
    -- Check if place has this trait (binary lookup via place_traits)
    SELECT EXISTS(
      SELECT 1 FROM place_traits 
      WHERE place_id = v_place_id AND trait_id = p_trait_id
    ) INTO v_has_trait;
    
    -- Determine multiplier based on answer and trait ownership
    -- YES + has_trait = boost (candidate matches affirmed trait)
    -- YES + !has_trait = penalty (candidate lacks affirmed trait)
    -- NO + has_trait = penalty (candidate has denied trait)
    -- NO + !has_trait = boost (candidate correctly lacks denied trait)
    IF p_answer = 'yes' THEN
      IF v_has_trait THEN
        v_multiplier := v_boost_factor;
      ELSE
        v_multiplier := v_penalty_factor;
      END IF;
    ELSE  -- p_answer = 'no'
      IF v_has_trait THEN
        v_multiplier := v_penalty_factor;
      ELSE
        v_multiplier := v_boost_factor;
      END IF;
    END IF;
    
    -- Apply multiplicative adjustment
    v_new_score := v_current_score * v_multiplier;
    
    -- Clamp score to valid range [0.01, 1.0]
    v_new_score := GREATEST(0.01, LEAST(1.0, v_new_score));
    
    -- Update candidate with new score
    v_result := v_result || jsonb_build_array(
      v_candidate || jsonb_build_object('confidence', v_new_score)
    );
  END LOOP;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."adjust_candidates_for_answer" (JSONB, UUID, answer_value) owner TO postgres;


comment ON function "game_logic"."adjust_candidates_for_answer" (JSONB, UUID, answer_value) IS 'Adjusts candidate scores using binary trait matching and multiplicative scaling.

Algorithm (per docs/architecture/algorithm.md#trait-matching):
1. For each candidate, check if place has the trait via place_traits table (binary)
2. Apply multiplier based on answer and trait ownership:
   - YES + has_trait → boost_factor (1.5)
   - YES + !has_trait → penalty_factor (0.6)  
   - NO + has_trait → penalty_factor (0.6)
   - NO + !has_trait → boost_factor (1.5)
3. new_score = old_score × multiplier

Why binary matching instead of embedding similarity?
- We have explicit place_traits relationships (ground truth)
- No fuzzy matching needed - place either has trait or not
- Faster and more accurate than embedding comparison

Parameters:
- p_candidates: JSONB array of candidates with confidence scores
- p_trait_id: The trait being asked about
- p_answer: yes, no, or not_sure (not_sure returns unchanged)

Returns: Updated JSONB array with adjusted confidence scores';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/adjust_score.sql
-- --------------------------------------------------------------------------

-- Function: adjust_score
-- Category: algorithm
-- Purpose: Adjust candidate score based on answer using power-law scaling
-- Spec: openspec/specs/algorithm/spec.md#score-adjustment
CREATE OR REPLACE FUNCTION "game_logic"."adjust_score" (
  p_current_score FLOAT,
  p_match_strength FLOAT,
  p_match_zone TEXT,
  p_answer TEXT, -- 'yes', 'no', 'not_sure'
  p_base_weight FLOAT DEFAULT 0.3,
  p_beta FLOAT DEFAULT 1.5
) returns FLOAT language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_magnitude FLOAT;
  v_adjustment FLOAT;
BEGIN
  -- Not sure = no adjustment
  IF p_answer = 'not_sure' THEN
    RETURN p_current_score;
  END IF;
  
  -- Calculate adjustment magnitude with power-law scaling
  -- magnitude = base_weight * match_strength^beta
  v_magnitude := p_base_weight * power(p_match_strength, p_beta);
  
  -- Determine adjustment direction based on answer and match zone
  IF p_answer = 'yes' THEN
    IF p_match_zone IN ('STRONG', 'PARTIAL') THEN
      -- YES + strong/partial match = boost (place has affirmed trait)
      v_adjustment := v_magnitude;
    ELSE
      -- YES + weak match = penalty (place lacks affirmed trait)
      v_adjustment := -v_magnitude;
    END IF;
  ELSIF p_answer = 'no' THEN
    IF p_match_zone IN ('STRONG', 'PARTIAL') THEN
      -- NO + strong/partial match = penalty (place has denied trait)
      v_adjustment := -v_magnitude;
    ELSE
      -- NO + weak match = boost (place correctly lacks denied trait)
      v_adjustment := v_magnitude * 0.5;  -- Smaller boost for "doesn't have"
    END IF;
  ELSE
    v_adjustment := 0;
  END IF;
  
  RETURN p_current_score + v_adjustment;
END;
$$;


ALTER FUNCTION "game_logic"."adjust_score" (FLOAT, FLOAT, TEXT, TEXT, FLOAT, FLOAT) owner TO postgres;


comment ON function "game_logic"."adjust_score" (FLOAT, FLOAT, TEXT, TEXT, FLOAT, FLOAT) IS 'Adjusts candidate score based on answer using power-law scaling.

Formula: magnitude = base_weight * match_strength^beta

Adjustment rules:
- YES + STRONG/PARTIAL match: positive (boost - place has affirmed trait)
- YES + WEAK match: negative (penalty - place lacks affirmed trait)
- NO + STRONG/PARTIAL match: negative (penalty - place has denied trait)
- NO + WEAK match: positive (boost - place correctly lacks denied trait)
- NOT SURE: no adjustment

Parameters:
- p_base_weight: Base weight for adjustments (default 0.3)
- p_beta: Power-law exponent (default 1.5)';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/apply_softmax_to_candidates.sql
-- --------------------------------------------------------------------------

-- Function: apply_softmax_to_candidates
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Apply softmax to convert candidate scores to probabilities
-- Spec: spec/algorithm.md#probability-distribution
CREATE OR REPLACE FUNCTION "game_logic"."apply_softmax_to_candidates" (
  p_candidates JSONB,
  p_temperature FLOAT DEFAULT 1.0
) returns JSONB language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_scores FLOAT[];
  v_probabilities FLOAT[];
  v_candidate JSONB;
  v_result JSONB := '[]'::JSONB;
  v_idx INT := 1;
BEGIN
  -- Handle empty candidates
  IF p_candidates IS NULL OR jsonb_array_length(p_candidates) = 0 THEN
    RETURN '[]'::JSONB;
  END IF;
  
  -- Extract scores from candidates
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_scores := array_append(v_scores, COALESCE((v_candidate->>'confidence')::FLOAT, 0.5));
  END LOOP;
  
  -- Calculate probabilities via softmax
  v_probabilities := softmax_probabilities(v_scores, p_temperature);
  
  -- Update candidates with probabilities and re-sort by probability DESC
  v_idx := 1;
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    v_result := v_result || jsonb_build_array(
      v_candidate || jsonb_build_object('probability', v_probabilities[v_idx])
    );
    v_idx := v_idx + 1;
  END LOOP;
  
  -- Sort by probability descending
  SELECT jsonb_agg(c ORDER BY (c->>'probability')::FLOAT DESC)
  INTO v_result
  FROM jsonb_array_elements(v_result) c;
  
  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;


ALTER FUNCTION "game_logic"."apply_softmax_to_candidates" (JSONB, FLOAT) owner TO postgres;


comment ON function "game_logic"."apply_softmax_to_candidates" (JSONB, FLOAT) IS 'Applies softmax to convert candidate confidence scores to probabilities.

Per spec (algorithm.md#probability-distribution):
P(place_i) = exp(score_i / temperature) / sum(exp(score_j / temperature))

After adjustments, recalculate probability distribution via softmax.

Parameters:
- p_candidates: JSONB array of candidates with confidence scores
- p_temperature: Softmax temperature (default 1.0)

Returns: JSONB array with added "probability" field, sorted by probability DESC';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/calculate_dynamic_threshold.sql
-- --------------------------------------------------------------------------

-- Function: calculate_dynamic_threshold
-- Category: algorithm
-- Purpose: Calculate dynamic guess threshold based on turn, candidate count, and margin
-- Spec: openspec/changes/add-smart-confidence-thresholds/specs/algorithm/spec.md
CREATE OR REPLACE FUNCTION "game_logic"."calculate_dynamic_threshold" (
  p_current_turn INT,
  p_max_turns INT,
  p_candidate_count INT,
  p_margin FLOAT
) returns FLOAT language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_threshold_max FLOAT;
  v_threshold_min FLOAT;
  v_threshold_floor FLOAT;
  v_threshold_ceiling FLOAT;
  v_candidate_low_threshold INT;
  v_candidate_bonus FLOAT;
  v_margin_high_threshold FLOAT;
  v_margin_bonus FLOAT;
  v_base_threshold FLOAT;
  v_progress FLOAT;
  v_result FLOAT;
BEGIN
  -- Read all configuration knobs
  v_threshold_max := get_config_float('confidence.guess_threshold_max', 0.90);
  v_threshold_min := get_config_float('confidence.guess_threshold_min', 0.60);
  v_threshold_floor := get_config_float('confidence.threshold_floor', 0.50);
  v_threshold_ceiling := get_config_float('confidence.threshold_ceiling', 0.95);
  v_candidate_low_threshold := get_config_int('confidence.candidate_low_threshold', 3);
  v_candidate_bonus := get_config_float('confidence.candidate_bonus', 0.10);
  v_margin_high_threshold := get_config_float('confidence.margin_high_threshold', 0.25);
  v_margin_bonus := get_config_float('confidence.margin_bonus', 0.10);
  
  -- Calculate progress through game: 0.0 at turn 0, 1.0 at max_turns
  IF p_max_turns <= 0 THEN
    v_progress := 1.0;  -- Safety: treat invalid max_turns as final turn
  ELSE
    v_progress := LEAST(1.0, p_current_turn::FLOAT / p_max_turns::FLOAT);
  END IF;
  
  -- Linear interpolation: start with threshold_max, decrease to threshold_min
  -- base = max - (max - min) * progress
  v_base_threshold := v_threshold_max - (v_threshold_max - v_threshold_min) * v_progress;
  
  -- Apply candidate bonus if few candidates remain
  IF p_candidate_count <= v_candidate_low_threshold THEN
    v_base_threshold := v_base_threshold - v_candidate_bonus;
  END IF;
  
  -- Apply margin bonus if gap between top two is large
  IF p_margin >= v_margin_high_threshold THEN
    v_base_threshold := v_base_threshold - v_margin_bonus;
  END IF;
  
  -- Clamp between floor and ceiling
  v_result := GREATEST(v_threshold_floor, LEAST(v_threshold_ceiling, v_base_threshold));
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."calculate_dynamic_threshold" (INT, INT, INT, FLOAT) owner TO postgres;


comment ON function "game_logic"."calculate_dynamic_threshold" (INT, INT, INT, FLOAT) IS 'Calculates dynamic guess threshold based on game progress and board state.

Input parameters:
- p_current_turn: Current turn number (0-indexed)
- p_max_turns: Maximum turns in game
- p_candidate_count: Number of remaining candidates
- p_margin: Margin between top two candidates (top_prob - second_prob)

Algorithm:
1. Base threshold interpolates linearly from guess_threshold_max (turn 0) to guess_threshold_min (final turn)
2. Apply candidate_bonus if candidate_count <= candidate_low_threshold
3. Apply margin_bonus if margin >= margin_high_threshold
4. Clamp result between threshold_floor and threshold_ceiling

Configuration keys (with defaults):
- confidence.guess_threshold_max (0.90)
- confidence.guess_threshold_min (0.60)
- confidence.threshold_floor (0.50)
- confidence.threshold_ceiling (0.95)
- confidence.candidate_low_threshold (3)
- confidence.candidate_bonus (0.10)
- confidence.margin_high_threshold (0.25)
- confidence.margin_bonus (0.10)

Returns: FLOAT threshold value (clamped between floor and ceiling)';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/calculate_split_quality.sql
-- --------------------------------------------------------------------------

-- Function: calculate_split_quality
-- Category: algorithm
-- Purpose: Calculate how evenly a question splits candidates
-- Spec: openspec/specs/algorithm/spec.md#question-split-quality
CREATE OR REPLACE FUNCTION "game_logic"."calculate_split_quality" (p_matching_count INT, p_total_count INT) returns FLOAT language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_fraction FLOAT;
BEGIN
  -- Edge cases
  IF p_total_count <= 0 THEN
    RETURN 0;
  END IF;
  
  IF p_total_count = 1 THEN
    RETURN 0;  -- Can't split a single candidate
  END IF;
  
  -- Calculate fraction matching
  v_fraction := p_matching_count::FLOAT / p_total_count::FLOAT;
  
  -- Split quality = 1 - |0.5 - fraction|
  -- 0.5 fraction = 1.0 quality (perfect split)
  -- 0.0 or 1.0 fraction = 0.5 quality (useless question)
  RETURN 1 - abs(0.5 - v_fraction);
END;
$$;


ALTER FUNCTION "game_logic"."calculate_split_quality" (INT, INT) owner TO postgres;


comment ON function "game_logic"."calculate_split_quality" (INT, INT) IS 'Calculates how evenly a question splits candidates.

Formula: split_quality = 1 - |0.5 - fraction|
Where: fraction = matching_count / total_count

Quality interpretation:
- 1.0: Perfect split (50% match)
- 0.75: Good split (25% or 75% match)
- 0.5: Useless question (0% or 100% match)

Returns value between 0.5 and 1.0.';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/confidence_metrics.sql
-- --------------------------------------------------------------------------

-- Function: calculate_confidence_metrics
-- Category: algorithm
-- Purpose: Calculate top_prob, margin, and normalized_entropy for guess decision
-- Spec: openspec/specs/algorithm/spec.md#confidence-decision-metrics
CREATE OR REPLACE FUNCTION "game_logic"."calculate_confidence_metrics" (p_probabilities FLOAT[]) returns TABLE (
  top_prob FLOAT,
  margin FLOAT,
  normalized_entropy FLOAT
) language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_top_prob FLOAT := 0;
  v_second_prob FLOAT := 0;
  v_entropy FLOAT := 0;
  v_count INT;
  v_prob FLOAT;
  i INT;
BEGIN
  v_count := COALESCE(array_length(p_probabilities, 1), 0);
  
  -- Edge cases
  IF v_count = 0 THEN
    RETURN QUERY SELECT 0::FLOAT, 0::FLOAT, 1::FLOAT;
    RETURN;
  END IF;
  
  IF v_count = 1 THEN
    RETURN QUERY SELECT 1::FLOAT, 1::FLOAT, 0::FLOAT;
    RETURN;
  END IF;
  
  -- Find top two probabilities and calculate entropy
  FOR i IN 1..v_count LOOP
    v_prob := p_probabilities[i];
    
    -- Track top two
    IF v_prob > v_top_prob THEN
      v_second_prob := v_top_prob;
      v_top_prob := v_prob;
    ELSIF v_prob > v_second_prob THEN
      v_second_prob := v_prob;
    END IF;
    
    -- Calculate entropy: -sum(P(i) * ln(P(i)))
    IF v_prob > 0 THEN
      v_entropy := v_entropy - (v_prob * ln(v_prob));
    END IF;
  END LOOP;
  
  -- Return metrics
  RETURN QUERY SELECT 
    v_top_prob,
    v_top_prob - v_second_prob AS margin,
    -- Normalized entropy: entropy / ln(candidate_count)
    CASE 
      WHEN v_count > 1 THEN v_entropy / ln(v_count::FLOAT)
      ELSE 0
    END AS normalized_entropy;
END;
$$;


ALTER FUNCTION "game_logic"."calculate_confidence_metrics" (FLOAT[]) owner TO postgres;


comment ON function "game_logic"."calculate_confidence_metrics" (FLOAT[]) IS 'Calculates confidence metrics for guess decision.

Returns:
- top_prob: max(P(place_i)) - highest probability
- margin: P(top) - P(second) - gap between top two
- normalized_entropy: entropy / ln(candidate_count)
  - 0 = certain (one candidate dominates)
  - 1 = maximum uncertainty (uniform distribution)

Used by should_guess() to determine if confidence thresholds are met.';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/filter_by_geography.sql
-- --------------------------------------------------------------------------

-- Function: filter_candidates_by_geography
-- Category: algorithm
-- Purpose: Filter candidates via PostGIS for geographic YES/NO answers
-- Spec: openspec/specs/algorithm/spec.md#spatial-filtering
CREATE OR REPLACE FUNCTION "game_logic"."filter_candidates_by_geography" (
  p_candidates JSONB,
  p_region_id UUID,
  p_answer TEXT -- 'yes' or 'no'
) returns JSONB language plpgsql
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_region_geom geometry;
  v_filtered JSONB := '[]'::JSONB;
  v_candidate JSONB;
  v_place_geom geometry;
  v_contains BOOLEAN;
BEGIN
  -- Get region geometry
  SELECT geom INTO v_region_geom
  FROM geographic_regions
  WHERE id = p_region_id;
  
  IF v_region_geom IS NULL THEN
    RAISE EXCEPTION 'Geographic region % not found', p_region_id;
  END IF;
  
  -- Filter each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    -- Get place geometry
    SELECT geom INTO v_place_geom
    FROM places
    WHERE id = (v_candidate->>'id')::UUID;
    
    IF v_place_geom IS NOT NULL THEN
      -- Check if region contains place
      v_contains := ST_Contains(v_region_geom, v_place_geom);
      
      -- YES answer: keep places IN the region
      -- NO answer: keep places NOT IN the region
      IF (p_answer = 'yes' AND v_contains) OR (p_answer = 'no' AND NOT v_contains) THEN
        v_filtered := v_filtered || v_candidate;
      END IF;
    END IF;
  END LOOP;
  
  RETURN v_filtered;
END;
$$;


ALTER FUNCTION "game_logic"."filter_candidates_by_geography" (JSONB, UUID, TEXT) owner TO postgres;


comment ON function "game_logic"."filter_candidates_by_geography" (JSONB, UUID, TEXT) IS 'Filters candidates via PostGIS for geographic answers.

Geographic YES answer:
- candidates = filter(ST_Contains(region, place.geom))

Geographic NO answer:  
- candidates = filter(NOT ST_Contains(region, place.geom))

Parameters:
- p_candidates: JSONB array of candidates with id field
- p_region_id: Geographic region UUID
- p_answer: ''yes'' or ''no''

Returns: Filtered JSONB array of candidates';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/filter_candidates_for_geography.sql
-- --------------------------------------------------------------------------

-- Function: filter_candidates_for_geography
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Filter candidates based on geographic answer (YES = inside, NO = outside)
-- Spec: spec/algorithm.md#spatial-filtering
CREATE OR REPLACE FUNCTION "game_logic"."filter_candidates_for_geography" (
  p_candidates JSONB,
  p_geographic_region_id UUID,
  p_answer answer_value
) returns JSONB language plpgsql
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_region_geom geometry;
  v_candidate JSONB;
  v_place_geom geometry;
  v_is_inside BOOLEAN;
  v_result JSONB := '[]'::JSONB;
BEGIN
  -- Get region geometry
  SELECT geom INTO v_region_geom
  FROM geographic_regions
  WHERE id = p_geographic_region_id;
  
  IF v_region_geom IS NULL THEN
    RAISE EXCEPTION 'Geographic region % not found', p_geographic_region_id;
  END IF;
  
  -- Process each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    -- Parse geometry from WKT stored in candidate
    v_place_geom := ST_GeomFromText(v_candidate->>'geom_wkt', 4326);
    
    -- Check if place intersects with region
    v_is_inside := ST_Intersects(v_place_geom, v_region_geom);
    
    -- Per spec:
    -- YES answer → keep only candidates INSIDE the region
    -- NO answer → keep only candidates OUTSIDE the region
    -- NOT_SURE → keep all candidates (no filtering)
    IF p_answer = 'not_sure' THEN
      v_result := v_result || jsonb_build_array(v_candidate);
    ELSIF (p_answer = 'yes' AND v_is_inside) OR (p_answer = 'no' AND NOT v_is_inside) THEN
      v_result := v_result || jsonb_build_array(v_candidate);
    END IF;
  END LOOP;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."filter_candidates_for_geography" (JSONB, UUID, answer_value) owner TO postgres;


comment ON function "game_logic"."filter_candidates_for_geography" (JSONB, UUID, answer_value) IS 'Filters candidates based on geographic answer.

Per spec (algorithm.md#spatial-filtering):
- Geographic Answer (YES): candidates = candidates.filter(ST_Contains(affirmed_region, place.geom))
- Geographic Answer (NO): candidates = candidates.filter(NOT ST_Contains(denied_region, place.geom))
- Geographic Answer (NOT_SURE): no filtering, keep all candidates

Uses ST_Intersects for proper geometry comparison (works with points, polygons, etc.)

Parameters:
- p_candidates: JSONB array of candidates with geom_wkt
- p_geographic_region_id: UUID of the geographic region
- p_answer: yes (inside), no (outside), not_sure (no filter)

Returns: Filtered JSONB array (candidates matching the geographic constraint)';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/select_best_question.sql
-- --------------------------------------------------------------------------

-- Function: select_best_question
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Select best question (geographic or semantic) based on split quality
-- Spec: openspec/specs/algorithm/spec.md#question-selection-algorithm
-- Spec: openspec/specs/algorithm/spec.md#geographic-vs-semantic-questions
CREATE OR REPLACE FUNCTION "game_logic"."select_best_question" (
  p_session_id UUID,
  p_candidates JSONB,
  p_geographic_preference_threshold FLOAT,
  p_min_split_quality FLOAT
) returns TABLE (
  question_type TEXT,
  trait_id UUID,
  geographic_region_id UUID,
  question_text TEXT,
  split_quality FLOAT
) language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_candidate_count INT;
  v_best_geo_question RECORD;
  v_best_semantic_question RECORD;
BEGIN
  v_candidate_count := jsonb_array_length(p_candidates);
  
  IF v_candidate_count <= 1 THEN
    RETURN;  -- No point asking questions with 0-1 candidates
  END IF;
  
  -- Find best geographic question (already filters out asked questions)
  SELECT * INTO v_best_geo_question
  FROM get_geographic_questions(p_session_id, p_candidates, 1);
  
  -- Find best semantic question (already filters out asked questions)
  SELECT * INTO v_best_semantic_question
  FROM get_semantic_questions(p_session_id, p_candidates, 1);
  
  -- Decision: prefer geographic if split quality >= threshold
  IF v_best_geo_question.split_quality >= p_geographic_preference_threshold THEN
    RETURN QUERY SELECT 
      'geographic'::TEXT,
      NULL::UUID,
      v_best_geo_question.geographic_region_id,
      v_best_geo_question.question_text,
      v_best_geo_question.split_quality;
    RETURN;
  END IF;
  
  -- Fall back to semantic if it has better quality
  IF v_best_semantic_question.split_quality >= COALESCE(v_best_geo_question.split_quality, 0) THEN
    RETURN QUERY SELECT 
      'semantic'::TEXT,
      v_best_semantic_question.trait_id,
      NULL::UUID,
      v_best_semantic_question.question_text,
      v_best_semantic_question.split_quality;
    RETURN;
  END IF;
  
  -- Use geographic if available (even if below threshold)
  IF v_best_geo_question.geographic_region_id IS NOT NULL THEN
    RETURN QUERY SELECT 
      'geographic'::TEXT,
      NULL::UUID,
      v_best_geo_question.geographic_region_id,
      v_best_geo_question.question_text,
      v_best_geo_question.split_quality;
    RETURN;
  END IF;
  
  -- Use semantic if available
  IF v_best_semantic_question.trait_id IS NOT NULL THEN
    RETURN QUERY SELECT 
      'semantic'::TEXT,
      v_best_semantic_question.trait_id,
      NULL::UUID,
      v_best_semantic_question.question_text,
      v_best_semantic_question.split_quality;
    RETURN;
  END IF;
  
  -- No questions available
  RETURN;
END;
$$;


ALTER FUNCTION "game_logic"."select_best_question" (UUID, JSONB, FLOAT, FLOAT) owner TO postgres;


comment ON function "game_logic"."select_best_question" (UUID, JSONB, FLOAT, FLOAT) IS 'Selects best question using geographic vs semantic decision logic.

Per spec (algorithm.md#geographic-vs-semantic-questions):
1. Calculate best geographic question split_quality
2. Calculate best semantic question split_quality
3. IF geographic_split >= geographic_preference_threshold → Ask geographic
4. ELSE → Ask whichever has higher split_quality

Decision rules:
1. If best geographic split >= threshold (default 0.7), use geographic (binary filter is simpler)
2. Else use whichever has higher split_quality
3. Already-asked questions filtered by get_geographic_questions and get_semantic_questions

Parameters:
- p_geographic_preference_threshold: Threshold to prefer geographic (default 0.7)
- p_min_split_quality: Minimum acceptable split quality (default 0.6)

Returns: question_type, trait_id OR geographic_region_id, question_text, split_quality

NOTE: This is an internal function that should be in game_logic schema (not client-accessible).';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/should_guess.sql
-- --------------------------------------------------------------------------

-- Function: should_guess
-- Category: algorithm
-- Purpose: Decide whether to guess based on confidence thresholds
-- Spec: openspec/specs/algorithm/spec.md#guess-decision-rule
CREATE OR REPLACE FUNCTION "game_logic"."should_guess" (
  p_probabilities FLOAT[],
  p_top_prob_threshold FLOAT DEFAULT 0.4,
  p_margin_threshold FLOAT DEFAULT 0.15,
  p_entropy_threshold FLOAT DEFAULT 0.7
) returns BOOLEAN language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_metrics RECORD;
  v_count INT;
BEGIN
  v_count := COALESCE(array_length(p_probabilities, 1), 0);
  
  -- Edge case: single candidate = automatic guess
  IF v_count = 1 THEN
    RETURN TRUE;
  END IF;
  
  -- Edge case: no candidates = cannot guess
  IF v_count = 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Get confidence metrics
  SELECT * INTO v_metrics FROM calculate_confidence_metrics(p_probabilities);
  
  -- All three thresholds must pass
  -- top_prob >= threshold AND margin >= threshold AND entropy <= threshold
  RETURN (
    v_metrics.top_prob >= p_top_prob_threshold
    AND v_metrics.margin >= p_margin_threshold
    AND v_metrics.normalized_entropy <= p_entropy_threshold
  );
END;
$$;


ALTER FUNCTION "game_logic"."should_guess" (FLOAT[], FLOAT, FLOAT, FLOAT) owner TO postgres;


comment ON function "game_logic"."should_guess" (FLOAT[], FLOAT, FLOAT, FLOAT) IS 'Decides whether to guess based on confidence thresholds.

Decision Rule (ALL must pass):
- top_prob >= threshold (default 0.4)
- margin >= threshold (default 0.15)  
- normalized_entropy <= threshold (default 0.7)

Edge cases:
- Single candidate: automatic guess (returns TRUE)
- Zero candidates: cannot guess (returns FALSE)
- All scores identical: all thresholds fail, ask question

Returns TRUE if should guess, FALSE if should ask question.';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/softmax_probabilities.sql
-- --------------------------------------------------------------------------

-- Function: softmax_probabilities
-- Category: algorithm
-- Purpose: Convert raw scores to probability distribution via softmax with temperature
-- Spec: openspec/specs/algorithm/spec.md#probability-distribution
CREATE OR REPLACE FUNCTION "game_logic"."softmax_probabilities" (p_scores FLOAT[], p_temperature FLOAT DEFAULT 1.0) returns FLOAT[] language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_max_score FLOAT;
  v_exp_scores FLOAT[];
  v_sum_exp FLOAT := 0;
  v_probabilities FLOAT[];
  i INT;
BEGIN
  -- Handle edge cases
  IF p_scores IS NULL OR array_length(p_scores, 1) IS NULL THEN
    RETURN ARRAY[]::FLOAT[];
  END IF;
  
  IF array_length(p_scores, 1) = 1 THEN
    RETURN ARRAY[1.0]::FLOAT[];
  END IF;
  
  -- Prevent division by zero
  IF p_temperature <= 0 THEN
    p_temperature := 0.001;
  END IF;
  
  -- Find max score for numerical stability (subtract max before exp)
  v_max_score := p_scores[1];
  FOR i IN 2..array_length(p_scores, 1) LOOP
    IF p_scores[i] > v_max_score THEN
      v_max_score := p_scores[i];
    END IF;
  END LOOP;
  
  -- Calculate exp(score_i / temperature) for each score
  v_exp_scores := ARRAY[]::FLOAT[];
  FOR i IN 1..array_length(p_scores, 1) LOOP
    v_exp_scores := array_append(v_exp_scores, exp((p_scores[i] - v_max_score) / p_temperature));
    v_sum_exp := v_sum_exp + v_exp_scores[i];
  END LOOP;
  
  -- Calculate probabilities: P(i) = exp(score_i/T) / sum(exp(score_j/T))
  v_probabilities := ARRAY[]::FLOAT[];
  FOR i IN 1..array_length(v_exp_scores, 1) LOOP
    v_probabilities := array_append(v_probabilities, v_exp_scores[i] / v_sum_exp);
  END LOOP;
  
  RETURN v_probabilities;
END;
$$;


ALTER FUNCTION "game_logic"."softmax_probabilities" (FLOAT[], FLOAT) owner TO postgres;


comment ON function "game_logic"."softmax_probabilities" (FLOAT[], FLOAT) IS 'Converts raw scores to probability distribution via softmax.

Formula: P(place_i) = exp(score_i / temperature) / sum(exp(score_j / temperature))

Parameters:
- p_scores: Array of raw similarity scores
- p_temperature: Temperature parameter (default 1.0)
  - Lower temperature = sharper distribution (amplifies differences)
  - Higher temperature = flatter distribution

Returns: Array of probabilities that sum to 1.0

Uses numerical stability trick: subtracts max score before exp to prevent overflow.';

-- --------------------------------------------------------------------------
-- game_logic/functions/algorithm/trait_match_strength.sql
-- --------------------------------------------------------------------------

-- Function: calculate_trait_match_strength
-- Category: algorithm
-- Purpose: Calculate match strength and zone for trait-place pairs
-- Spec: openspec/specs/algorithm/spec.md#trait-match-scoring
CREATE OR REPLACE FUNCTION "game_logic"."calculate_trait_match_strength" (
  p_place_embedding extensions.vector (384),
  p_trait_embedding extensions.vector (384),
  p_strong_threshold FLOAT DEFAULT 0.7,
  p_partial_threshold FLOAT DEFAULT 0.5
) returns TABLE (match_strength FLOAT, match_zone TEXT) language plpgsql immutable
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_similarity FLOAT;
BEGIN
  -- Calculate cosine similarity (1 - cosine distance)
  v_similarity := 1 - (p_place_embedding <=> p_trait_embedding);
  
  -- Determine match zone
  RETURN QUERY SELECT 
    v_similarity,
    CASE
      WHEN v_similarity >= p_strong_threshold THEN 'STRONG'
      WHEN v_similarity >= p_partial_threshold THEN 'PARTIAL'
      ELSE 'WEAK'
    END AS match_zone;
END;
$$;


ALTER FUNCTION "game_logic"."calculate_trait_match_strength" (
  extensions.vector (384),
  extensions.vector (384),
  FLOAT,
  FLOAT
) owner TO postgres;


comment ON function "game_logic"."calculate_trait_match_strength" (
  extensions.vector (384),
  extensions.vector (384),
  FLOAT,
  FLOAT
) IS 'Calculates match strength between place and trait embeddings.

Match zones:
- STRONG: match_strength >= strong_threshold (default 0.7)
- PARTIAL: match_strength >= partial_threshold (default 0.5)
- WEAK: below partial_threshold

Returns:
- match_strength: cosine similarity (0-1)
- match_zone: STRONG, PARTIAL, or WEAK';

-- --------------------------------------------------------------------------
-- game_logic/functions/apply_answer_to_session_state.sql
-- --------------------------------------------------------------------------

-- Function: apply_answer_to_session_state
-- Category: game
-- Applies a player's answer to the session state
-- Geographic questions affect bounding boxes via game_answers
CREATE OR REPLACE FUNCTION "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic AS $$
DECLARE
  v_session_record RECORD;
BEGIN
  -- Get current session state
  SELECT * INTO v_session_record
  FROM game_sessions gs
  WHERE gs.id = p_session_id;
  
  IF v_session_record.id IS NULL THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;
  
  -- Answer state is recorded in game_answers table
  -- Geographic filtering uses game_answers to determine bbox inclusion/exclusion
  -- No session state update needed here
END;
$$;


ALTER FUNCTION "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) owner TO "postgres";


comment ON function "game_logic"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" answer_value,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID
) IS 'Applies a user answer to the session.

Behavior:
- Answer state is recorded in game_answers table
- Geographic questions affect bounding boxes via game_answers
- Semantic questions affect candidate scoring via game_answers

Parameters:
- p_session_id: Session ID
- p_answer: User answer (yes/no/not_sure)
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
';

-- --------------------------------------------------------------------------
-- game_logic/functions/decide_next_turn.sql
-- --------------------------------------------------------------------------

-- Function: decide_next_turn
-- Category: game
-- Purpose: Decide whether to guess or ask a question based on current candidates
-- Builds complete next_turn JSONB with action and candidates
-- Updated to use new algorithm functions for probability-based decision making
CREATE OR REPLACE FUNCTION "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) returns void language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_candidates JSONB;
  v_candidate_count INT;
  v_confidence_scores FLOAT[];
  v_probabilities FLOAT[];
  v_confidence_metrics RECORD;
  v_should_guess BOOLEAN;
  v_top_candidate JSONB;
  v_question_record RECORD;
  v_next_turn JSONB;
  v_total_turns INT;
  v_max_turns INT;
  v_softmax_temperature FLOAT;
  v_top_prob_threshold FLOAT;
  v_margin_threshold FLOAT;
  v_entropy_threshold FLOAT;
BEGIN
  -- Get configuration from game_logic.config (FAIL if missing)
  v_max_turns := get_max_turns();
  
  v_softmax_temperature := get_config_float('scoring.temperature');
  
  v_top_prob_threshold := get_config_float('confidence.top_prob_threshold');
  
  v_margin_threshold := get_config_float('confidence.margin_threshold');
  
  v_entropy_threshold := get_config_float('confidence.entropy_threshold');

  -- Get current turn count
  SELECT COUNT(*) INTO v_total_turns
  FROM game_answers ga
  WHERE ga.session_id = p_session_id;

  -- Use provided candidates
  v_candidates := p_candidates;
  v_candidate_count := jsonb_array_length(p_candidates);

  -- Check if game over (exceeded max_turns)
  IF v_total_turns > v_max_turns THEN
    UPDATE game_sessions
    SET next_turn = NULL, was_correct = FALSE
    WHERE id = p_session_id;
    
    RETURN;
  END IF;

  -- Zero candidates: give up
  IF v_candidate_count = 0 THEN
    UPDATE game_sessions
    SET next_turn = jsonb_build_object(
      'action', 'give_up',
      'reason', 'no_candidates'
    )
    WHERE id = p_session_id;
    
    RETURN;
  END IF;

  -- Extract confidence scores from candidates and convert to probabilities
  SELECT ARRAY_AGG((elem->>'confidence')::FLOAT ORDER BY (elem->>'confidence')::FLOAT DESC)
  INTO v_confidence_scores
  FROM jsonb_array_elements(v_candidates) elem;
  
  -- Convert scores to probability distribution using softmax
  v_probabilities := softmax_probabilities(v_confidence_scores, v_softmax_temperature);
  
  -- Calculate confidence metrics (top_prob, margin, normalized_entropy)
  SELECT * INTO v_confidence_metrics
  FROM calculate_confidence_metrics(v_probabilities);
  
  -- Make guess decision using algorithm function
  v_should_guess := should_guess(
    v_probabilities,
    v_top_prob_threshold,
    v_margin_threshold,
    v_entropy_threshold
  );
  
  -- Get top candidate for guess
  SELECT elem INTO v_top_candidate
  FROM jsonb_array_elements(v_candidates) elem
  ORDER BY (elem->>'confidence')::FLOAT DESC
  LIMIT 1;

  -- Apply guess policy using algorithm-based decision
  -- Guess if: at max_turns, algorithm says to guess, or only 1 candidate
  IF v_total_turns >= v_max_turns
     OR v_should_guess = TRUE
     OR v_candidate_count = 1
  THEN
    -- Build GUESS next_turn using pure formatter (SRP)
    v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
  ELSE
    -- Ask a question: call get_question with candidates
    SELECT * INTO v_question_record
    FROM get_question(p_session_id, v_candidates)
    LIMIT 1;
    
    IF v_question_record.question_type IS NULL THEN
      -- No differentiating questions available - fall back to guess
      -- This happens when remaining candidates share all traits/regions
      v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
    ELSE
      -- Build QUESTION next_turn using pure formatter (SRP)
      v_next_turn := build_question_turn(
        v_question_record.question_type,
        v_question_record.trait_id,
        v_question_record.geographic_region_id,
        v_question_record.question_text,
        v_question_record.question_reasoning,
        v_candidates
      );
    END IF;
  END IF;

  -- Store next_turn
  UPDATE game_sessions
  SET next_turn = v_next_turn
  WHERE id = p_session_id;

END;
$$;


ALTER FUNCTION "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) owner TO "postgres";


comment ON function "game_logic"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) IS 'Orchestrates next turn decision: guess or question using algorithm functions.

Parameters:
- p_session_id: Session ID
- p_candidates: Candidates JSONB array (caller must provide)

Responsibilities (SRP - Orchestration only):
1. Get/validate candidates
2. Extract confidence scores and convert to probabilities using softmax_probabilities()
3. Calculate confidence metrics using calculate_confidence_metrics()
4. Make guess decision using should_guess() with proper thresholds
5. Call get_question() if asking question (delegates to question domain)
6. Call build_guess_turn() or build_question_turn() for formatting (pure functions)
7. Update database with next_turn

Algorithm Integration:
- Uses softmax_probabilities() to convert scores to probability distribution
- Uses calculate_confidence_metrics() for top_prob, margin, normalized_entropy
- Uses should_guess() for evidence-based guess decisions
- Replaces hardcoded confidence thresholds with algorithmic approach

Returns next_turn JSONB structure:
- {"action": "guess", "place_id": "...", "place_name": "...", "candidates": [...]}
- {"action": "question", "question_id": "...", "question_text": "...", "candidates": [...]}
- NULL (if no candidates available)

Called by:
- start_game() after creating new session (fetches candidates first)
- handle_question() after user answers question (passes candidates)
- handle_guess() after wrong guess (passes candidates)

Configuration (from app_settings):
- max_turns, softmax_temperature, top_prob_threshold, margin_threshold, entropy_threshold

Returns: VOID (side-effect only)';

-- --------------------------------------------------------------------------
-- game_logic/functions/filter_geographic_candidates.sql
-- --------------------------------------------------------------------------

-- Function: filter_geographic_candidates
-- Category: game
-- Purpose: Apply geographic filters and calculate distance metrics
-- Returns: Places that pass geographic criteria + distance from region center
CREATE OR REPLACE FUNCTION "game_logic"."filter_geographic_candidates" ("p_session_id" UUID) returns TABLE (
  id UUID,
  name TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  geom extensions.geometry,
  embedding_id UUID,
  distance_from_bbox_center DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_include_regions geometry[];
  v_exclude_regions geometry[];
BEGIN
  -- Get actual geometries from answered geographic questions
  SELECT ARRAY_AGG(gr.geom)
  INTO v_include_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = 'yes'::answer_value
    AND ga.geographic_region_id IS NOT NULL;

  SELECT ARRAY_AGG(gr.geom)
  INTO v_exclude_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = 'no'::answer_value
    AND ga.geographic_region_id IS NOT NULL;

  -- Apply geographic filters and calculate distance metrics
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    p.geom,
    p.embedding_id,
    -- Calculate distance from center of smallest (most specific) include region
    CASE 
      WHEN v_include_regions IS NOT NULL THEN
        (
          SELECT ST_Distance(
            p.geom::geography,
            ST_Centroid(region_geom)::geography
          )
          FROM UNNEST(v_include_regions) AS region_geom
          ORDER BY ST_Area(region_geom::geography) ASC
          LIMIT 1
        )
      ELSE NULL
    END AS distance_from_bbox_center
  FROM places p
  WHERE p.geom IS NOT NULL
    -- Exclude places pending review
    AND p.pending_review = FALSE
    -- Exclude wrong guesses
    AND NOT EXISTS (
      SELECT 1 FROM game_answers ga
      WHERE ga.session_id = p_session_id
        AND ga.place_id = p.id
        AND ga.trait_id IS NULL
        AND ga.geographic_region_id IS NULL
    )
    -- Include: Place must intersect with ALL include regions (AND logic)
    AND (
      v_include_regions IS NULL
      OR (
        SELECT COUNT(*)
        FROM UNNEST(v_include_regions) AS region_geom
        WHERE ST_Intersects(p.geom, region_geom)
      ) = array_length(v_include_regions, 1)
    )
    -- Exclude: Place must NOT intersect with ANY exclude region (OR logic)
    AND (
      v_exclude_regions IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM UNNEST(v_exclude_regions) AS region_geom
        WHERE ST_Intersects(p.geom, region_geom)
      )
    );
END;
$$;


ALTER FUNCTION "game_logic"."filter_geographic_candidates" ("p_session_id" UUID) owner TO "postgres";


comment ON function "game_logic"."filter_geographic_candidates" ("p_session_id" UUID) IS 'Filters places by geographic criteria using actual geometries and calculates distance metrics.

Uses ST_Intersects for accurate geometry-based filtering (works for Point, Polygon, MultiPolygon places).

Applies:
- Region inclusion (answered YES to geographic questions) - place must intersect ALL include regions
- Region exclusion (answered NO to geographic questions) - place must NOT intersect ANY exclude region
- Wrong guess exclusion (previously guessed incorrectly)

Calculates:
- distance_from_bbox_center: Distance (meters) from center of smallest include region

Returns: Places that pass geographic filters + distance metrics.

Called by: get_candidates() as first filtering step.';

-- --------------------------------------------------------------------------
-- game_logic/functions/filter_semantic_candidates.sql
-- --------------------------------------------------------------------------

-- Function: filter_semantic_candidates
-- Category: game
-- Purpose: Calculate semantic similarity scores using softmax-weighted trait aggregation
-- Returns: Place IDs with aggregated similarity scores
CREATE OR REPLACE FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) returns TABLE (
  place_id UUID,
  base_description_similarity DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_description_embedding vector(384);
  v_threshold FLOAT;
  v_temperature FLOAT;
BEGIN
  -- Get configuration from game_logic.config
  v_threshold := get_config_float('scoring.initial_candidate_threshold', 0.5);
  v_temperature := get_config_float('scoring.trait_aggregation_temperature', 0.1);

  -- Get session embedding
  SELECT
    e.embedding
  INTO
    v_description_embedding
  FROM game_sessions gs
  JOIN embeddings e ON e.id = gs.embedding_id
  WHERE gs.id = p_session_id;

  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', p_session_id;
  END IF;

  -- Calculate softmax-weighted trait similarity aggregation
  -- Formula: score = Σ(softmax(sim/τ) × sim)
  -- where softmax(sim_i/τ) = exp(sim_i/τ) / Σexp(sim_j/τ)
  RETURN QUERY
  WITH trait_similarities AS (
    -- Calculate similarity between description and each trait for each place
    SELECT
      pt.place_id AS pid,
      (1 - (te.embedding <=> v_description_embedding))::DOUBLE PRECISION AS sim
    FROM
      place_traits pt
      JOIN traits t ON t.id = pt.trait_id
      JOIN embeddings te ON te.id = t.embedding_id
    WHERE
      pt.place_id = ANY (p_place_ids)
      AND te.embedding IS NOT NULL
  ),
  exp_similarities AS (
    -- Calculate exp(sim/τ) for softmax
    SELECT
      pid,
      sim,
      exp(sim / v_temperature) AS exp_sim
    FROM trait_similarities
  ),
  softmax_weights AS (
    -- Calculate softmax weights: exp(sim/τ) / Σexp(sim/τ)
    SELECT
      pid,
      sim,
      exp_sim,
      SUM(exp_sim) OVER (PARTITION BY pid) AS sum_exp
    FROM exp_similarities
  ),
  aggregated_scores AS (
    -- Calculate weighted average: Σ(weight × sim)
    SELECT
      pid AS place_id,
      SUM((exp_sim / NULLIF(sum_exp, 0)) * sim)::DOUBLE PRECISION AS aggregated_score
    FROM softmax_weights
    GROUP BY pid
  )
  SELECT
    a.place_id,
    a.aggregated_score AS base_description_similarity
  FROM aggregated_scores a
  WHERE a.aggregated_score > v_threshold;
END;
$$;


ALTER FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) owner TO "postgres";


comment ON function "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) IS 'Calculates semantic similarity using softmax-weighted trait aggregation.

Algorithm:
1. For each place, compute similarity between description and each trait embedding
2. Apply softmax weighting: weight_i = exp(sim_i/τ) / Σexp(sim_j/τ)
3. Calculate weighted average: score = Σ(weight_i × sim_i)
4. Filter by threshold

The softmax temperature (τ) controls how much the best traits dominate:
- τ → 0: Approaches MAX (only best trait matters)
- τ = 0.1: Top 2-3 traits dominate (default)
- τ → ∞: Approaches simple average

This approach handles both:
- Categorical queries ("religious site") - matches specific traits well
- Specific queries ("tall iron tower in Paris") - multiple traits contribute

Input:
- p_session_id: Session to get description embedding from
- p_place_ids: Array of place IDs to score

Returns: place_id and aggregated score for places above threshold.

Called by: get_candidates() which joins with geographic results.';

-- --------------------------------------------------------------------------
-- game_logic/functions/get_candidates.sql
-- --------------------------------------------------------------------------

-- Function: get_candidates
-- Category: game
-- Purpose: Orchestrate candidate filtering and apply business logic (scoring weights)
-- Returns: JSONB array of candidates (use jsonb_array_length for count)
CREATE OR REPLACE FUNCTION "game_logic"."get_candidates" ("session_id_param" "uuid") returns JSONB language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_geo_fit_max_weight FLOAT;
  v_distance_normalization FLOAT;
  v_result JSONB;
BEGIN
  -- Get scoring configuration from game_logic.config
  v_geo_fit_max_weight := get_config_float('scoring.geographic_fit_max_weight', 0.2);
  v_distance_normalization := get_config_float('scoring.distance_normalization', 20000000.0);

  -- Orchestrate filtering and scoring pipeline
  WITH geographic_filtered AS (
    -- Step 1: Apply geographic filters + distance calculation (cheap PostGIS operations)
    SELECT * FROM filter_geographic_candidates(session_id_param)
  ),
  place_ids AS (
    -- Step 2: Extract place IDs to pass to semantic filter
    SELECT ARRAY_AGG(id) AS ids FROM geographic_filtered
  ),
  semantic_scored AS (
    -- Step 3: Calculate semantic similarities for filtered places (expensive vector operations)
    SELECT * 
    FROM filter_semantic_candidates(session_id_param, (SELECT ids FROM place_ids))
    WHERE (SELECT ids FROM place_ids) IS NOT NULL
  ),
  candidates AS (
    SELECT
      gf.id,
      gf.name,
      gf.lat,
      gf.lng,
      gf.geom,
      ss.base_description_similarity,
      gf.distance_from_bbox_center,
      (
        ss.base_description_similarity  -- Base similarity
        + CASE
            WHEN gf.distance_from_bbox_center IS NOT NULL THEN
              -- Geographic fit bonus: closer to bbox center = higher bonus
              v_geo_fit_max_weight * (1 - LEAST(gf.distance_from_bbox_center / v_distance_normalization, 1.0))
            ELSE 0.0
          END
      ) AS confidence
    FROM geographic_filtered gf
    JOIN semantic_scored ss ON ss.place_id = gf.id
  ),
  ranked_candidates AS (
    SELECT
      c.id,
      c.name,
      c.lat,
      c.lng,
      c.geom,
      c.base_description_similarity,
      c.distance_from_bbox_center,
      c.confidence
    FROM candidates c
    ORDER BY c.confidence DESC
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', rc.id,
          'name', rc.name,
          'lat', rc.lat,
          'lng', rc.lng,
          'geom_wkt', ST_AsText(rc.geom),
          'description_similarity', rc.base_description_similarity::FLOAT,
          'geographic_distance', rc.distance_from_bbox_center::FLOAT,
          'confidence', rc.confidence::FLOAT
        ) ORDER BY rc.confidence DESC
      ),
      '[]'::JSONB
    ) INTO v_result
  FROM ranked_candidates rc;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."get_candidates" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "game_logic"."get_candidates" ("session_id_param" "uuid") IS 'Orchestrates candidate filtering and applies business logic (SOLID architecture).

Pipeline:
1. filter_geographic_candidates(session_id) → places + distance_from_bbox_center
2. Extract place IDs from geographic results
3. filter_semantic_candidates(session_id, place_ids[]) → similarity scores
4. Join geographic + semantic results
5. Apply business logic: base similarity + geographic fit scoring

Scoring formula (business logic - ALL VALUES CONFIGURABLE via game_logic.config):
- Base: base_description_similarity
- Geographic fit: scoring.geographic_fit_max_weight * (1 - distance/scoring.distance_normalization)

Configuration (from game_logic.config):
- scoring.geographic_fit_max_weight (default 0.2): Maximum geographic fit bonus
- scoring.distance_normalization (default 20000000): Distance normalization (~20000km)

Filtering:
- Geographic: bbox inclusion/exclusion + wrong guess exclusion
- Semantic: base_description_similarity > semantic_similarity_threshold (default 0.5)
- NO LIMIT: Returns ALL candidates above threshold (count used by decide_next_turn)

Returns: JSONB array of ALL candidates above threshold, ordered by confidence DESC. Use jsonb_array_length() for count.
  Each candidate contains:
  - id, name, lat, lng: Basic place info
  - description_similarity: Raw base similarity (0-1)
  - geographic_distance: Distance in meters from bbox center (null if no bbox)
  - confidence: Final composite score with weights applied
Optimized: Returns JSONB directly to avoid repeated conversions.';

-- --------------------------------------------------------------------------
-- game_logic/functions/get_question.sql
-- --------------------------------------------------------------------------

-- Function: get_question
-- Category: game
-- Chooses the best question using algorithmic selection (split_quality)
-- Per docs/architecture/algorithm.md: "Selection is deterministic and algorithmic"
CREATE OR REPLACE FUNCTION "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) returns TABLE (
  "question_type" question_type,
  "trait_id" UUID,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_result RECORD;
  v_geographic_preference_threshold FLOAT;
  v_min_split_quality FLOAT;
  v_use_llm_questions BOOLEAN;
  v_language_code TEXT;
  v_user_description TEXT;
  v_generated_text TEXT;
BEGIN
  -- Get configuration values
  v_geographic_preference_threshold := get_config_float('questions.geographic_preference_threshold', 0.7);
  v_min_split_quality := get_config_float('questions.min_split_quality', 0.3);
  v_use_llm_questions := get_config('questions.use_llm_generation')::text = 'true';
  
  -- Get language and description from session
  SELECT language_code, description INTO v_language_code, v_user_description
  FROM game_sessions
  WHERE id = p_session_id;
  v_language_code := COALESCE(v_language_code, 'en');
  
  -- Use algorithmic selection based on split_quality (per spec)
  -- select_best_question already filters out already-asked questions
  SELECT * INTO v_result
  FROM select_best_question(
    p_session_id, 
    p_candidates, 
    v_geographic_preference_threshold, 
    v_min_split_quality
  )
  LIMIT 1;
  
  IF v_result.question_type IS NULL THEN
    -- No questions available (all traits asked or no candidates)
    RETURN;
  END IF;
  
  -- Generate question text
  IF v_use_llm_questions THEN
    -- Use LLM to generate natural question text
    -- No fallback: if LLM fails, exception propagates and game crashes
    v_generated_text := generate_question_text(
      v_result.trait_id,
      v_result.geographic_region_id,
      v_language_code,
      v_user_description
    );
    
    IF v_generated_text IS NULL OR v_generated_text = '' THEN
      RAISE EXCEPTION 'LLM returned empty question text for session %', p_session_id;
    END IF;
  ELSE
    -- LLM disabled: use templates (not a fallback, this is configured behavior)
    IF v_result.question_type = 'semantic' THEN
      v_generated_text := 'Does it have ' || COALESCE((SELECT clause FROM traits WHERE id = v_result.trait_id), v_result.trait_id) || '?';
    ELSIF v_result.question_type = 'geographic' THEN
      v_generated_text := 'Is it in ' || (SELECT name FROM geographic_regions WHERE id = v_result.geographic_region_id) || '?';
    ELSE
      RAISE EXCEPTION 'Unknown question type: %', v_result.question_type;
    END IF;
  END IF;
  
  RETURN QUERY SELECT
    v_result.question_type::question_type,
    v_result.trait_id,
    v_result.geographic_region_id,
    v_generated_text,
    ('Split quality: ' || COALESCE(round(v_result.split_quality::numeric, 2)::text, 'N/A'))::TEXT as question_reasoning;
END;
$$;


ALTER FUNCTION "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) owner TO "postgres";


comment ON function "game_logic"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) IS 'Selects best question using algorithmic split_quality ranking.

Per docs/architecture/algorithm.md:
- Selection is deterministic and algorithmic
- LLM is used only to phrase questions (optional), not to choose them
- Uses select_best_question which considers geographic vs semantic preference

Returns: question_type, trait_id/geographic_region_id, question_text, reasoning';

-- --------------------------------------------------------------------------
-- game_logic/functions/handle_guess.sql
-- --------------------------------------------------------------------------

-- Function: handle_guess
-- Category: game
-- Purpose: Handle guess confirmation (SRP - Single Responsibility)
CREATE OR REPLACE FUNCTION "game_logic"."handle_guess" (
  "p_answer" answer_value,
  "p_session_record" record
) returns void language plpgsql
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_eliminated_place_id UUID;
  v_candidates JSONB;
  v_candidates_after JSONB;
BEGIN
  -- Correct guess - mark session as won
  IF p_answer = 'yes' THEN
    UPDATE game_sessions
    SET 
      place_id = (p_session_record.next_turn->>'place_id')::uuid,
      was_correct = TRUE,
      next_turn = NULL
    WHERE id = p_session_record.id;

    RETURN;
  END IF;

  -- Wrong guess - record it and continue
  v_eliminated_place_id := (p_session_record.next_turn->>'place_id')::uuid;

  -- Get candidates from next_turn (state at answer time - FREE!)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Record wrong guess (metrics derived later, not stored)
  PERFORM record_game_answer(
    p_session_record.id,
    NULL,  -- No trait
    NULL,  -- No geographic region
    'no'::answer_value,
    v_eliminated_place_id,
    NULL,
    v_candidates
  );

  -- Get candidates AFTER removing wrong guess (ONLY call to get_candidates)
  -- get_candidates excludes places with game_answers entries (question_id IS NULL)
  v_candidates_after := get_candidates(p_session_record.id);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "game_logic"."handle_guess" (
  "p_answer" answer_value,
  "p_session_record" record
) owner TO "postgres";


comment ON function "game_logic"."handle_guess" (
  "p_answer" answer_value,
  "p_session_record" record
) IS 'Handle guess confirmation (YES/NO answer to a guess).

Responsibilities (SRP):
- Correct guess: Mark session as won
- Wrong guess: Record answer with snapshot, exclude place, continue game

Storage strategy (no duplication):
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once
- AFTER state stored in next next_turn (becomes BEFORE for next answer)
- No redundancy: Each state stored exactly once

Returns: VOID (raises exception on error)
Extracted from play_turn for Single Responsibility Principle.';

-- --------------------------------------------------------------------------
-- game_logic/functions/handle_question.sql
-- --------------------------------------------------------------------------

-- Function: handle_question
-- Category: game
-- Purpose: Handle question answer (SRP - Single Responsibility)
-- Spec: spec/algorithm.md#turn-flow
CREATE OR REPLACE FUNCTION "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) returns void language plpgsql
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_question_type question_type;
  v_trait_id UUID;
  v_geographic_region_id UUID;
  v_question_text TEXT;
  v_candidates JSONB;
  v_candidates_after JSONB;
  v_temperature FLOAT;
BEGIN
  -- Get question details from next_turn
  v_question_type := (p_session_record.next_turn->>'question_type')::question_type;
  v_trait_id := p_session_record.next_turn->>'trait_id';
  v_geographic_region_id := (p_session_record.next_turn->>'geographic_region_id')::uuid;
  v_question_text := p_session_record.next_turn->>'question_text';

  IF v_question_type IS NULL THEN
    RAISE EXCEPTION 'Invalid next_turn: missing question_type';
  END IF;

  IF v_trait_id IS NULL AND v_geographic_region_id IS NULL THEN
    RAISE EXCEPTION 'Invalid next_turn: must have either trait_id or geographic_region_id';
  END IF;

  -- Get candidates from next_turn (state at answer time)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Get softmax temperature from config
  v_temperature := COALESCE(get_config_float('scoring.temperature'), 1.0);

  -- Update trait state (for trait arrays used by other functions)
  PERFORM apply_answer_to_session_state(
    p_session_record.id,
    p_answer,
    v_trait_id,
    v_geographic_region_id
  );

  -- Record answer with snapshot BEFORE adjustment
  PERFORM record_game_answer(
    p_session_record.id,
    v_trait_id,
    v_geographic_region_id,
    p_answer,
    p_session_record.place_id,
    v_question_text,
    v_candidates
  );

  -- Per spec: Apply answer based on question type
  -- Geographic = filter candidates (binary in/out)
  -- Semantic = adjust scores (multiplicative via place_traits)
  IF v_question_type = 'geographic' THEN
    -- Filter candidates using PostGIS
    v_candidates_after := filter_candidates_for_geography(
      v_candidates,
      v_geographic_region_id,
      p_answer
    );
  ELSE
    -- Adjust scores using power-law scaling
    v_candidates_after := adjust_candidates_for_answer(
      v_candidates,
      v_trait_id,
      p_answer
    );
  END IF;

  -- Recalculate probabilities via softmax (per spec)
  v_candidates_after := apply_softmax_to_candidates(v_candidates_after, v_temperature);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) owner TO "postgres";


comment ON function "game_logic"."handle_question" (
  "p_answer" answer_value,
  "p_session_record" record
) IS 'Handle question answer (YES/NO/NOT_SURE answer to a question).

Per spec (docs/architecture/algorithm.md#turn-flow):
1. Record Answer
2. Geographic or Semantic?
   - Geographic → Filter Candidates (ST_Contains)
   - Semantic → Adjust Scores (Multiplicative via place_traits)
3. Recalculate Probabilities (softmax)
4. Decide Next Turn

Responsibilities (SRP):
- Fetch question details from next_turn
- Record answer with snapshot BEFORE adjustment
- Apply answer based on question type:
  - Geographic: filter_candidates_for_geography (binary in/out)
  - Semantic: adjust_candidates_for_answer (multiplicative scoring)
- Recalculate probabilities via softmax
- Continue game via decide_next_turn

Score Adjustment (semantic answers):
- Uses adjust_candidates_for_answer with binary place_traits lookup
- new_score = old_score * multiplier (multiplicative)
- Multiplier based on trait ownership: boost_factor or penalty_factor

Storage strategy:
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once (snapshot before adjustment)
- Updated candidates stored in next next_turn

Returns: VOID (raises exception on error)';

-- --------------------------------------------------------------------------
-- game_logic/functions/maintenance/maintenance_cleanup.sql
-- --------------------------------------------------------------------------

-- Function: maintenance_cleanup
-- Category: maintenance
-- Deletes expired sessions, prunes question stats, and cleans up rate limit logs
CREATE OR REPLACE FUNCTION "game_logic"."maintenance_cleanup" () returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Delete expired sessions (no activity in 24 hours)
  DELETE FROM game_sessions gs
  WHERE COALESCE(
    (SELECT MAX(created_at) FROM game_answers WHERE session_id = gs.id),
    gs.created_at
  ) < NOW() - INTERVAL '24 hours';

  -- Prune question_stats beyond cap of 450
  -- Keep top 450 by effectiveness_score DESC, times_asked ASC, created_at ASC
  WITH ranked AS (
    SELECT id
    FROM game_logic.question_stats
    ORDER BY effectiveness_score DESC, times_asked ASC, created_at ASC
    OFFSET 450
  )
  DELETE FROM game_logic.question_stats
  WHERE id IN (SELECT id FROM ranked);

  -- Clean up old rate_limit_log entries (older than 1 hour)
  -- Rate limit entries are only needed for enforcement within the time window
  DELETE FROM game_logic.rate_limit_log
  WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$;


ALTER FUNCTION "game_logic"."maintenance_cleanup" () owner TO "postgres";


comment ON function "game_logic"."maintenance_cleanup" () IS 'Daily maintenance function that deletes expired sessions (24+ hours old)
and prunes question_stats to keep only the top 450 most effective ones.';

-- --------------------------------------------------------------------------
-- game_logic/functions/maintenance/maintenance_weekly.sql
-- --------------------------------------------------------------------------

-- Function: maintenance_weekly
-- Category: maintenance
-- TODO: Update for trait-based system
CREATE OR REPLACE FUNCTION "game_logic"."maintenance_weekly" () returns TABLE (
  "questions_duplicates_removed" INTEGER,
  "questions_kept" INTEGER,
  "places_duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_places_result RECORD;
BEGIN
  -- Run place deduplication
  SELECT * INTO v_places_result FROM deduplicate_places();

  RETURN QUERY SELECT
    0::INTEGER, -- questions deduplication removed for now
    0::INTEGER,
    v_places_result.duplicates_removed,
    v_places_result.places_kept;
END;
$$;


ALTER FUNCTION "game_logic"."maintenance_weekly" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- game_logic/functions/places/add_place.sql
-- --------------------------------------------------------------------------

-- Function: add_place
-- Category: places
-- Adds a place to the database with geometry from Nominatim (Point, Polygon, or MultiPolygon)
CREATE OR REPLACE FUNCTION "game_logic"."add_place" (
  p_name TEXT,
  p_osm_id TEXT,
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL,
  p_geojson JSONB DEFAULT NULL,
  p_pending_review BOOLEAN DEFAULT FALSE
) returns UUID language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place_id uuid;
  v_geom geometry;
  v_lat NUMERIC;
  v_lng NUMERIC;
BEGIN
  -- Validate name
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'INVALID_NAME: Place name cannot be empty';
  END IF;

  -- Validate osm_id
  IF p_osm_id IS NULL OR trim(p_osm_id) = '' THEN
    RAISE EXCEPTION 'INVALID_OSM_ID: OSM ID cannot be empty';
  END IF;

  -- Handle geometry: prefer geojson, fallback to lat/lng point
  IF p_geojson IS NOT NULL THEN
    -- Convert GeoJSON to PostGIS geometry (Point, Polygon, or MultiPolygon)
    v_geom := ST_SetSRID(ST_GeomFromGeoJSON(p_geojson::text), 4326);
    
    -- Calculate lat/lng from centroid if not provided
    IF p_lat IS NULL OR p_lng IS NULL THEN
      v_lat := ST_Y(ST_Centroid(v_geom));
      v_lng := ST_X(ST_Centroid(v_geom));
    ELSE
      v_lat := p_lat;
      v_lng := p_lng;
    END IF;
  ELSIF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    -- Fallback: create Point geometry from lat/lng
    IF p_lat < -90 OR p_lat > 90 THEN
      RAISE EXCEPTION 'INVALID_LATITUDE: Latitude must be between -90 and 90';
    END IF;
    IF p_lng < -180 OR p_lng > 180 THEN
      RAISE EXCEPTION 'INVALID_LONGITUDE: Longitude must be between -180 and 180';
    END IF;
    
    v_geom := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
    v_lat := p_lat;
    v_lng := p_lng;
  ELSE
    RAISE EXCEPTION 'INVALID_GEOMETRY: Must provide either geojson or lat/lng';
  END IF;

  -- Insert place
  INSERT INTO places (
    name,
    osm_id,
    lat,
    lng,
    geom,
    pending_review
  )
  VALUES (
    p_name,
    p_osm_id,
    v_lat,
    v_lng,
    v_geom,
    p_pending_review
  )
  ON CONFLICT (osm_id) DO UPDATE SET
    name = EXCLUDED.name,
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    geom = EXCLUDED.geom,
    pending_review = EXCLUDED.pending_review,
    updated_at = NOW()
  RETURNING id INTO v_place_id;

  RETURN v_place_id;
END;
$$;


ALTER FUNCTION "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) owner TO postgres;


GRANT
EXECUTE ON function "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) TO authenticated,
anon;


comment ON function "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) IS 'Adds a place to the database with geometry from Nominatim.

Parameters:
- p_name: Place name
- p_osm_id: OpenStreetMap ID (unique)
- p_lat: Latitude (optional if geojson provided)
- p_lng: Longitude (optional if geojson provided)
- p_geojson: GeoJSON geometry from Nominatim (Point, Polygon, or MultiPolygon)
- p_pending_review: Whether place needs review before being active

Geometry handling:
- If geojson provided: uses actual geometry, calculates lat/lng from centroid if needed
- If only lat/lng provided: creates Point geometry
- Supports upsert on osm_id conflict

Returns: place_id (UUID)';

-- --------------------------------------------------------------------------
-- game_logic/functions/places/approve_pending_place.sql
-- --------------------------------------------------------------------------

-- Function: approve_pending_place
-- Category: places
-- Purpose: Admin function to approve pending places (placeholder)
-- NOTE: Places don't have pending_review - sessions do. This function is for
-- direct place approval in case we add pending_review to places in future.
-- Currently returns success for any existing place.
CREATE OR REPLACE FUNCTION "game_logic"."approve_pending_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_place RECORD;
BEGIN
  -- Get place
  SELECT * INTO v_place FROM places WHERE id = p_place_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', p_place_id;
  END IF;

  -- Place exists - return success
  -- NOTE: Places table does not have pending_review column currently.
  -- Anonymous submissions go through game_sessions.pending_review instead.
  -- This function is kept for future extensibility.
  
  RETURN jsonb_build_object(
    'status', 'approved',
    'place_id', p_place_id,
    'name', v_place.name
  );
END;
$$;


ALTER FUNCTION "game_logic"."approve_pending_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "game_logic"."approve_pending_place" ("p_place_id" "uuid") IS 'Admin function for place approval.
NOTE: Currently places do not have pending_review - that is on game_sessions.
Use approve_pending_session trigger for anonymous submission approval.
This function returns success for any existing place.';

-- --------------------------------------------------------------------------
-- game_logic/functions/places/deduplicate_places.sql
-- --------------------------------------------------------------------------

-- Function: deduplicate_places
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."deduplicate_places" () returns TABLE (
  "duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_duplicates_removed INTEGER := 0;
  v_places_kept INTEGER := 0;
  v_place_record RECORD;
  v_similar_places UUID[];
  v_best_place_id UUID;
  v_total_times_encountered INTEGER;
  v_avg_confidence FLOAT;
  v_combined_descriptors JSONB;
BEGIN
  -- Find places with same nominatim_place_id (exact duplicates)
  FOR v_place_record IN
    SELECT
      p1.nominatim_place_id,
      array_agg(p1.id ORDER BY p1.times_encountered DESC, p1.created_at ASC) as place_ids
    FROM places p1
    WHERE p1.nominatim_place_id IS NOT NULL
      AND p1.pending_review = false
    GROUP BY p1.nominatim_place_id
    HAVING COUNT(*) > 1
  LOOP
    -- Keep the first place, merge others into it
    v_best_place_id := v_place_record.place_ids[1];
    v_similar_places := v_place_record.place_ids[2:array_length(v_place_record.place_ids, 1)];

    -- Calculate merged stats
    SELECT
      SUM(times_encountered),
      jsonb_object_agg(COALESCE(descriptors->>'key', ''), descriptors->>'value')
    INTO v_total_times_encountered, v_combined_descriptors
    FROM places
    WHERE id = ANY(v_similar_places || ARRAY[v_best_place_id]);

    -- Update the best place with merged stats
    UPDATE places
    SET
      times_encountered = v_total_times_encountered,
      descriptors = v_combined_descriptors,
      updated_at = NOW()
    WHERE id = v_best_place_id;

    -- Update game_sessions to point to the kept place
    UPDATE game_sessions
    SET place_id = v_best_place_id
    WHERE place_id = ANY(v_similar_places);

    -- Delete duplicates
    DELETE FROM places
    WHERE id = ANY(v_similar_places);

    v_duplicates_removed := v_duplicates_removed + array_length(v_similar_places, 1);
    v_places_kept := v_places_kept + 1;
  END LOOP;

  -- Find nearby places with similar names (within 100m, name similarity > 0.8)
  FOR v_place_record IN
    SELECT
      p1.id as place_id,
      p1.name as place_name,
      p1.lat,
      p1.lng,
      array_agg(p2.id) as similar_ids
    FROM places p1
    JOIN places p2 ON p1.id != p2.id
      AND ST_DWithin(p1.geom, p2.geom, 100)  -- Within 100 meters
      AND similarity(p1.name, p2.name) > 0.8  -- Name similarity > 80%
      AND p1.pending_review = false
      AND p2.pending_review = false
    WHERE p1.id < p2.id  -- Avoid duplicate pairs
    GROUP BY p1.id, p1.name, p1.lat, p1.lng
  LOOP
    -- Keep the place with more encounters, merge others
    SELECT id INTO v_best_place_id
    FROM places
    WHERE id = ANY(array_append(v_place_record.similar_ids, v_place_record.place_id))
    ORDER BY times_encountered DESC, created_at ASC
    LIMIT 1;

    v_similar_places := ARRAY[v_place_record.place_id] || v_place_record.similar_ids;
    v_similar_places := array_remove(v_similar_places, v_best_place_id);

    -- Calculate merged stats
    SELECT
      SUM(times_encountered),
      jsonb_object_agg(COALESCE(descriptors->>'key', ''), descriptors->>'value')
    INTO v_total_times_encountered, v_combined_descriptors
    FROM places
    WHERE id = ANY(v_similar_places || ARRAY[v_best_place_id]);

    -- Update the best place with merged stats
    UPDATE places
    SET
      times_encountered = v_total_times_encountered,
      descriptors = v_combined_descriptors,
      updated_at = NOW()
    WHERE id = v_best_place_id;

    -- Update game_sessions to point to the kept place
    UPDATE game_sessions
    SET place_id = v_best_place_id
    WHERE place_id = ANY(v_similar_places);

    -- Delete duplicates
    DELETE FROM places
    WHERE id = ANY(v_similar_places);

    v_duplicates_removed := v_duplicates_removed + array_length(v_similar_places, 1);
    v_places_kept := v_places_kept + 1;
  END LOOP;

  RETURN QUERY SELECT v_duplicates_removed, v_places_kept;
END;
$$;


ALTER FUNCTION "game_logic"."deduplicate_places" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- game_logic/functions/places/enrich_place.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place
-- Category: places
-- Purpose: Enrich a place with traits from recent sessions
-- Note: This is a convenience wrapper. The main learning happens via trigger.
CREATE OR REPLACE FUNCTION "game_logic"."enrich_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_session_record RECORD;
  v_result JSONB := '[]'::JSONB;
  v_learn_result JSONB;
BEGIN
  -- Find recent successful sessions for this place and learn from them
  FOR v_session_record IN
    SELECT id
    FROM game_sessions
    WHERE place_id = p_place_id
      AND was_correct = TRUE
    ORDER BY created_at DESC
    LIMIT 5  -- Learn from last 5 successful sessions
  LOOP
    v_learn_result := learn_traits_from_session(v_session_record.id, p_place_id);
    v_result := v_result || jsonb_build_array(v_learn_result);
  END LOOP;
  
  RETURN jsonb_build_object(
    'status', 'success',
    'sessions_processed', jsonb_array_length(v_result),
    'results', v_result
  );
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "game_logic"."enrich_place" ("p_place_id" "uuid") IS 'Enriches a place by learning traits from recent successful game sessions.

This is a convenience wrapper that can be called manually.
The primary learning happens automatically via the enrich_place_on_session_complete trigger.

Processes up to 5 most recent successful sessions for the place.';

-- --------------------------------------------------------------------------
-- game_logic/functions/places/learn_traits_from_session.sql
-- --------------------------------------------------------------------------

-- Function: learn_traits_from_session
-- Category: places
-- Purpose: Learn traits from a completed game session's answers
-- Spec: docs/architecture/algorithm.md#trait-sources
CREATE OR REPLACE FUNCTION "game_logic"."learn_traits_from_session" ("p_session_id" UUID, "p_place_id" UUID) returns JSONB language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_affirmed_count INT := 0;
  v_already_had_count INT := 0;
  v_trait_record RECORD;
BEGIN
  -- Learn from affirmed traits (YES answers to semantic questions)
  FOR v_trait_record IN
    SELECT ga.trait_id
    FROM game_answers ga
    WHERE ga.session_id = p_session_id
      AND ga.trait_id IS NOT NULL  -- Semantic questions only
      AND ga.answer = 'yes'        -- Affirmed traits
  LOOP
    -- Insert trait link if not already exists
    INSERT INTO place_traits (place_id, trait_id)
    VALUES (p_place_id, v_trait_record.trait_id)
    ON CONFLICT (place_id, trait_id) DO NOTHING;
    
    IF FOUND THEN
      v_affirmed_count := v_affirmed_count + 1;
    ELSE
      v_already_had_count := v_already_had_count + 1;
    END IF;
  END LOOP;
  
  -- Log learning result
  IF v_affirmed_count > 0 THEN
    RAISE NOTICE 'Learned % new traits for place % from session %', 
      v_affirmed_count, p_place_id, p_session_id;
  END IF;
  
  RETURN jsonb_build_object(
    'status', 'success',
    'traits_learned', v_affirmed_count,
    'traits_already_had', v_already_had_count,
    'session_id', p_session_id,
    'place_id', p_place_id
  );
END;
$$;


ALTER FUNCTION "game_logic"."learn_traits_from_session" (UUID, UUID) owner TO "postgres";


comment ON function "game_logic"."learn_traits_from_session" (UUID, UUID) IS 'Learns traits from a completed game session.

When a game completes successfully (user confirms the guess):
1. Gets all game_answers where trait_id IS NOT NULL and answer = ''yes''
2. Inserts those traits into place_traits (if not already there)

This enables the game to learn new traits about places over time.

Example flow:
1. User describes "tall iron structure with observation deck"
2. Game asks "Does it offer panoramic views?" (trait: feature:observation)
3. User answers YES
4. Game guesses Eiffel Tower, user confirms
5. If Eiffel Tower didn''t have feature:observation, it learns it now

Parameters:
- p_session_id: The completed session to learn from
- p_place_id: The place that was correctly guessed

Returns: JSONB with learning statistics';

-- --------------------------------------------------------------------------
-- game_logic/functions/places/match_places.sql
-- --------------------------------------------------------------------------

-- Function: match_places
-- Category: places
-- Purpose: Find places matching query embedding with geographic filters
-- Uses embedding_id FK to embeddings table (not direct embedding column)
CREATE OR REPLACE FUNCTION "game_logic"."match_places" (
  "query_embedding" "extensions"."vector",
  "constraint_text" "text" DEFAULT NULL::"text",
  "filters" "jsonb" DEFAULT '{}'::"jsonb",
  "match_threshold" DOUBLE PRECISION DEFAULT 0.1,
  "match_count" INTEGER DEFAULT 20
) returns TABLE (
  "id" "uuid",
  "name" "text",
  "lat" DOUBLE PRECISION,
  "lng" DOUBLE PRECISION,
  "descriptors" "jsonb",
  "semantic_similarity" DOUBLE PRECISION,
  "spatial_confidence" DOUBLE PRECISION,
  "composite_confidence" DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  centroid_geom geometry;
  max_distance float;
  spatial_score float;
  effective_embedding vector(384);
BEGIN
  effective_embedding := query_embedding;

  CREATE TEMP TABLE temp_candidates AS
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    NULL::jsonb as descriptors,  -- places table doesn't have descriptors column
    p.geom,
    1 - (e.embedding <=> effective_embedding) as sem_similarity
  FROM places p
  JOIN embeddings e ON e.id = p.embedding_id
  WHERE p.embedding_id IS NOT NULL
    AND p.geom IS NOT NULL
    AND 1 - (e.embedding <=> effective_embedding) > match_threshold
    -- Apply geographic filters from filters parameter
    AND (
      filters IS NULL
      OR NOT (filters ? 'include_bbox')
      OR (
        filters->>'include_bbox' IS NULL
        OR ST_Within(
          p.geom,
          ST_MakeEnvelope(
            (filters->'include_bbox'->0)::text::float,
            (filters->'include_bbox'->1)::text::float,
            (filters->'include_bbox'->2)::text::float,
            (filters->'include_bbox'->3)::text::float,
            4326
          )
        )
      )
    )
    AND (
      filters IS NULL
      OR NOT (filters ? 'exclude_bbox')
      OR (
        filters->>'exclude_bbox' IS NULL
        OR NOT ST_Within(
          p.geom,
          ST_MakeEnvelope(
            (filters->'exclude_bbox'->0)::text::float,
            (filters->'exclude_bbox'->1)::text::float,
            (filters->'exclude_bbox'->2)::text::float,
            (filters->'exclude_bbox'->3)::text::float,
            4326
          )
        )
      )
    )
  ORDER BY e.embedding <=> effective_embedding, p.id
  LIMIT match_count;

  SELECT ST_Centroid(ST_Collect(geom)) INTO centroid_geom
  FROM temp_candidates;

  SELECT MAX(ST_Distance(geom::geography, centroid_geom::geography)) INTO max_distance
  FROM temp_candidates;

  IF max_distance IS NULL OR max_distance = 0 THEN
    spatial_score := 1.0;
  ELSIF max_distance <= 50000 THEN
    spatial_score := 1.0;
  ELSIF max_distance <= 200000 THEN
    spatial_score := 0.7 + (0.3 * (1 - (max_distance - 50000) / 150000));
  ELSIF max_distance <= 500000 THEN
    spatial_score := 0.3 + (0.4 * (1 - (max_distance - 200000) / 300000));
  ELSE
    spatial_score := 0.2 * (1 - LEAST((max_distance - 500000) / 5000000, 1));
  END IF;

  RETURN QUERY
  SELECT
    tc.id,
    tc.name,
    tc.lat,
    tc.lng,
    tc.descriptors,
    tc.sem_similarity::float as semantic_similarity,
    spatial_score::float as spatial_confidence,
    (tc.sem_similarity * 0.95 + spatial_score * 0.05)::float as composite_confidence
  FROM temp_candidates tc
  ORDER BY (tc.sem_similarity * 0.95 + spatial_score * 0.05) DESC, tc.id;

  DROP TABLE temp_candidates;
END;
$$;

-- --------------------------------------------------------------------------
-- game_logic/functions/places/update_place_traits.sql
-- --------------------------------------------------------------------------

-- Function: update_place_traits
-- Category: places
-- Purpose: Unified trait extraction/update for a place
-- Replaces: extract_traits_from_nominatim, regenerate_place_traits
CREATE OR REPLACE FUNCTION "game_logic"."update_place_traits" ("p_place_id" UUID) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place RECORD;
  v_nominatim_data JSONB;
  v_nominatim_summary JSONB;
  v_session_descriptions TEXT[];
  v_game_answers TEXT[];
  v_existing_traits TEXT[];
  v_llm_prompt TEXT;
  v_llm_response TEXT;
  v_traits_json JSONB;
  v_trait RECORD;
  v_trait_id UUID;
  v_trait_clauses TEXT[];
  v_trait_embedding_id UUID;
  v_max_traits INT;
  v_extratags JSONB;
  v_filtered_extratags JSONB := '{}'::jsonb;
  v_address JSONB;
  v_key TEXT;
  v_extratags_exclude TEXT[] := ARRAY[
    'wikidata', 'wikipedia', 'wikimedia_commons', 'website', 'url', 'image',
    'phone', 'fax', 'email', 'opening_hours', 'check_date', 'fee',
    'source', 'operator', 'brand', 'network', 'panoramax',
    'ref', 'int_ref', 'nat_ref', 'loc_ref',
    'alt_name', 'old_name', 'short_name', 'official_name', 'loc_name',
    'wheelchair', 'toilets', 'internet_access', 'smoking',
    'layer', '3dmr', 'min_height'
  ];
BEGIN
  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_place_id IS NULL THEN
    RAISE EXCEPTION 'Place ID cannot be null';
  END IF;

  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    RETURN;
  END IF;

  -- Check if LLM is enabled
  IF NOT COALESCE((game_logic.get_config('llm.enabled')#>>'{}')::BOOLEAN, TRUE) THEN
    RETURN;
  END IF;

  -- ============================================================================
  -- GET PLACE DATA
  -- ============================================================================
  SELECT id, name, osm_id, lat, lng
  INTO v_place
  FROM places
  WHERE id = p_place_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place % not found', p_place_id;
  END IF;

  -- ============================================================================
  -- FETCH NOMINATIM DATA (if place has osm_id)
  -- ============================================================================
  IF v_place.osm_id IS NOT NULL THEN
    BEGIN
      v_nominatim_data := game_logic.fetch_nominatim_place(v_place.osm_id);
    EXCEPTION WHEN others THEN
      RAISE WARNING 'Failed to fetch Nominatim data for %: %', v_place.osm_id, SQLERRM;
      v_nominatim_data := '{}'::jsonb;
    END;
  ELSE
    v_nominatim_data := '{}'::jsonb;
  END IF;

  -- Filter extratags
  v_extratags := COALESCE(v_nominatim_data->'extratags', '{}'::jsonb);
  FOR v_key IN SELECT jsonb_object_keys(v_extratags)
  LOOP
    IF NOT (
      v_key = ANY(v_extratags_exclude) OR
      v_key LIKE 'contact:%' OR v_key LIKE 'name:%' OR v_key LIKE 'source:%' OR
      v_key LIKE 'ref:%' OR v_key LIKE 'payment:%' OR v_key LIKE 'addr:%' OR v_key LIKE 'image:%'
    ) THEN
      v_filtered_extratags := v_filtered_extratags || jsonb_build_object(v_key, v_extratags->v_key);
    END IF;
  END LOOP;

  v_address := COALESCE(v_nominatim_data->'address', '{}'::jsonb);

  -- Build nominatim summary for LLM
  v_nominatim_summary := jsonb_build_object(
    'class', v_nominatim_data->>'class',
    'type', v_nominatim_data->>'type',
    'extratags', v_filtered_extratags
  );

  -- ============================================================================
  -- GATHER CONTEXT
  -- ============================================================================
  
  -- Get session descriptions
  SELECT array_agg(DISTINCT description)
  INTO v_session_descriptions
  FROM game_sessions
  WHERE place_id = p_place_id
    AND description IS NOT NULL;

  -- Get game answers (trait-based answers from sessions)
  SELECT array_agg(
    CASE 
      WHEN ga.answer = 'yes' THEN '+ ' || COALESCE(t.clause, gr.name)
      WHEN ga.answer = 'no' THEN '- ' || COALESCE(t.clause, gr.name)
      ELSE '? ' || COALESCE(t.clause, gr.name)
    END
  )
  INTO v_game_answers
  FROM game_sessions gs
  JOIN game_answers ga ON ga.session_id = gs.id
  LEFT JOIN traits t ON t.id = ga.trait_id
  LEFT JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE gs.place_id = p_place_id
    AND gs.was_correct = TRUE;

  -- Get existing traits (just clauses, no IDs)
  SELECT array_agg(t.clause)
  INTO v_existing_traits
  FROM place_traits pt
  JOIN traits t ON t.id = pt.trait_id
  WHERE pt.place_id = p_place_id;

  -- Get max traits from config
  v_max_traits := COALESCE(get_config_int('llm.trait_extraction.max_traits'), 20);

  -- ============================================================================
  -- BUILD LLM PROMPT
  -- ============================================================================
  v_llm_prompt := get_config_text('llm.trait_extraction.prompt');
  v_llm_prompt := replace(v_llm_prompt, '{place_name}', COALESCE(v_place.name, 'Unknown'));
  v_llm_prompt := replace(v_llm_prompt, '{lat}', round(v_place.lat::numeric, 4)::text);
  v_llm_prompt := replace(v_llm_prompt, '{lng}', round(v_place.lng::numeric, 4)::text);
  v_llm_prompt := replace(v_llm_prompt, '{country}', COALESCE(v_address->>'country', 'Unknown'));
  v_llm_prompt := replace(v_llm_prompt, '{place_type}', COALESCE(v_nominatim_data->>'type', 'Unknown'));
  v_llm_prompt := replace(v_llm_prompt, '{nominatim_json}', COALESCE(v_nominatim_summary::text, 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{existing_traits}', COALESCE(array_to_string(v_existing_traits, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{session_descriptions}', COALESCE(array_to_string(v_session_descriptions, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{game_answers}', COALESCE(array_to_string(v_game_answers, E'\n'), 'None'));
  v_llm_prompt := replace(v_llm_prompt, '{max_traits}', v_max_traits::text);

  RAISE NOTICE 'Updating traits for place: %', v_place.name;

  -- ============================================================================
  -- CALL LLM
  -- ============================================================================
  v_llm_response := game_logic.call_llm_api(v_llm_prompt, 'json', 'llm.trait_extraction');

  -- ============================================================================
  -- PARSE RESPONSE
  -- ============================================================================
  BEGIN
    v_traits_json := v_llm_response::jsonb;
    
    IF jsonb_typeof(v_traits_json) = 'object' AND v_traits_json ? 'traits' THEN
      v_traits_json := v_traits_json->'traits';
    ELSIF jsonb_typeof(v_traits_json) != 'array' THEN
      RAISE EXCEPTION 'LLM response must be {"traits": [...]} or an array';
    END IF;
  EXCEPTION
    WHEN others THEN
      RAISE WARNING 'Failed to parse LLM trait response: %. Response: %', SQLERRM, left(v_llm_response, 200);
      RETURN;
  END;

  -- ============================================================================
  -- REPLACE TRAITS (delete old, insert new)
  -- ============================================================================
  
  -- Delete existing place_traits links (traits themselves are kept for other places)
  DELETE FROM place_traits WHERE place_id = p_place_id;

  -- Insert new traits (array of strings)
  FOR v_trait IN
    SELECT t AS clause
    FROM jsonb_array_elements_text(v_traits_json) AS t
    WHERE length(trim(t)) > 1
      AND length(trim(t)) <= 500
    LIMIT v_max_traits
  LOOP
    -- Generate embedding for trait clause (use 'passage' since traits are matched against queries)
    v_trait_embedding_id := get_embedding(v_trait.clause, 'passage');

    -- Insert trait with generated UUID (deduplication happens via embedding_id)
    INSERT INTO traits (id, clause, embedding_id)
    VALUES (gen_random_uuid(), v_trait.clause, v_trait_embedding_id)
    ON CONFLICT (embedding_id) DO UPDATE SET
      clause = EXCLUDED.clause
    RETURNING id INTO v_trait_id;

    -- Link trait to place
    INSERT INTO place_traits (place_id, trait_id)
    VALUES (p_place_id, v_trait_id)
    ON CONFLICT (place_id, trait_id) DO NOTHING;

    -- Collect for place embedding
    v_trait_clauses := array_append(v_trait_clauses, v_trait.clause);
  END LOOP;

  -- ============================================================================
  -- UPDATE PLACE STATUS
  -- ============================================================================
  -- Note: Place embedding is NOT updated here - algorithm uses individual trait embeddings.
  -- Place embedding only exists as fallback for legacy data without trait embeddings.
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    UPDATE places
    SET 
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;

    RAISE NOTICE 'Updated % traits for place %', array_length(v_trait_clauses, 1), v_place.name;
  ELSE
    UPDATE places
    SET 
      pending_review = FALSE,
      updated_at = NOW()
    WHERE id = p_place_id;

    RAISE WARNING 'No traits extracted for place %', v_place.name;
  END IF;

EXCEPTION
  WHEN others THEN
    RAISE WARNING 'update_place_traits failed for place %: %', p_place_id, SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."update_place_traits" (UUID) owner TO "postgres";


comment ON function "game_logic"."update_place_traits" (UUID) IS 'Unified trait extraction and update for a place.

Gathers all available context:
- Nominatim data (class, type, extratags)
- Existing traits
- Session descriptions from gameplay
- Game answers (yes/no responses)

Calls LLM to produce the best 10-20 traits, then REPLACES all traits for the place.
The LLM decides what to keep, add, or drop based on all available information.

Called by:
- create_place_with_traits (initial creation)
- Trigger after session approval
- Manual enrichment

Replaces: extract_traits_from_nominatim, regenerate_place_traits';

-- --------------------------------------------------------------------------
-- game_logic/functions/questions/get_geographic_questions.sql
-- --------------------------------------------------------------------------

-- Function: get_geographic_questions
-- Category: questions
-- Returns geographic regions to generate questions from, ranked by split quality
-- Spec: openspec/specs/algorithm/spec.md#geographic-vs-semantic-questions
CREATE OR REPLACE FUNCTION "game_logic"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER DEFAULT NULL
) returns TABLE (
  "geographic_region_id" "uuid",
  "region_name" "text",
  "region_level" "text",
  "split_quality" DOUBLE PRECISION,
  "yes_count" INTEGER,
  "no_count" INTEGER,
  "question_text" TEXT
) language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_shallowest_confirmed_level geographic_level;
  v_confirmed_regions geometry[];
BEGIN
  -- Find the shallowest (broadest) confirmed geographic level
  SELECT MIN(gr.level::geographic_level)
  INTO v_shallowest_confirmed_level
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = 'yes'::answer_value
    AND ga.geographic_region_id IS NOT NULL;

  -- Get all confirmed regions as geometries for spatial filtering
  SELECT ARRAY_AGG(gr.geom)
  INTO v_confirmed_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = 'yes'::answer_value
    AND ga.geographic_region_id IS NOT NULL;

  RETURN QUERY
  WITH candidate_geoms AS (
    -- Convert candidate JSONB to geometries (supports Point, Polygon, MultiPolygon)
    SELECT 
      (c->>'id')::uuid as place_id,
      ST_GeomFromText((c->>'geom_wkt')::text, 4326) as geom
    FROM jsonb_array_elements(p_candidates) c
  ),
  region_splits AS (
    -- Calculate how each region splits the candidates
    SELECT
      gr.id,
      gr.name,
      gr.level,
      COALESCE(qs.effectiveness_score, 0.5) as effectiveness_score,
      COALESCE(qs.times_asked, 0) as times_asked,
      -- Count candidates that intersect with region (YES answers)
      COUNT(*) FILTER (WHERE ST_Intersects(cg.geom, gr.geom)) as yes_count,
      -- Count candidates that don't intersect with region (NO answers)
      COUNT(*) FILTER (WHERE NOT ST_Intersects(cg.geom, gr.geom)) as no_count,
      -- Information gain: 1.0 = perfect 50/50 split, 0.0 = all yes or all no
      CASE 
        WHEN COUNT(*) = 0 THEN 0.0
        ELSE 1.0 - ABS(0.5 - (COUNT(*) FILTER (WHERE ST_Intersects(cg.geom, gr.geom))::float / COUNT(*)))
      END as information_gain
    FROM geographic_regions gr
    CROSS JOIN candidate_geoms cg
    LEFT JOIN game_logic.question_stats qs ON qs.geographic_region_id = gr.id
    WHERE
      -- Don't ask same region twice
      gr.id NOT IN (
        SELECT ga.geographic_region_id
        FROM game_answers ga
        WHERE ga.session_id = p_session_id
          AND ga.geographic_region_id IS NOT NULL
      )
      -- Level filter: once a level is confirmed, only ask about deeper levels
      AND (
        v_shallowest_confirmed_level IS NULL
        OR gr.level::geographic_level > v_shallowest_confirmed_level
      )
      -- Spatial filter: must intersect with confirmed regions (if any)
      AND (
        v_confirmed_regions IS NULL
        OR EXISTS (
          SELECT 1
          FROM UNNEST(v_confirmed_regions) AS confirmed_geom
          WHERE ST_Intersects(confirmed_geom, gr.geom)
        )
      )
    GROUP BY gr.id, gr.name, gr.level, qs.effectiveness_score, qs.times_asked
    HAVING 
      -- CRITICAL: Only return regions that actually SPLIT the candidates
      COUNT(*) FILTER (WHERE ST_Intersects(cg.geom, gr.geom)) > 0  -- Some YES
      AND COUNT(*) FILTER (WHERE NOT ST_Intersects(cg.geom, gr.geom)) > 0  -- Some NO
  )
  SELECT
    rs.id as geographic_region_id,
    rs.name as region_name,
    rs.level as region_level,
    rs.information_gain as split_quality,
    rs.yes_count::INTEGER,
    rs.no_count::INTEGER,
    NULL as question_text  -- Will be generated by LLM later
  FROM region_splits rs
  -- Order by split quality (best splits first), then effectiveness
  ORDER BY rs.information_gain DESC, rs.effectiveness_score DESC, rs.times_asked ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "game_logic"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) owner TO "postgres";


comment ON function "game_logic"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) IS 'Returns geographic regions to generate questions from (e.g., "Is it in {region_name}?").

CANDIDATE-AWARE: Uses actual place geometries (Point, Polygon, MultiPolygon) from candidates to calculate split quality.

Uses ST_Intersects for accurate geometry-based split calculation (works for all geometry types).

Filters by:
1. Level hierarchy: Must be deeper than shallowest confirmed level
2. Spatial intersection: Must intersect with confirmed regions
3. Not already asked in this session
4. MUST SPLIT CANDIDATES: Only returns regions where some candidates intersect and some don''t

Ranking:
1. split_quality (1.0 = perfect 50/50 split, 0.5 = useless question)

Progressive narrowing: continent → country

Returns: geographic_region_id, region_name, region_level, split_quality, yes_count, no_count, question_text.
Consistent return format with get_semantic_questions for use by select_best_question.';

-- --------------------------------------------------------------------------
-- game_logic/functions/questions/get_semantic_questions.sql
-- --------------------------------------------------------------------------

-- Function: get_semantic_questions
-- Category: questions
-- Returns traits to generate semantic questions from, ranked by split quality
-- Uses place_traits relationship (ground truth) for split quality calculation
-- Spec: docs/architecture/algorithm.md#question-selection
CREATE OR REPLACE FUNCTION "game_logic"."get_semantic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER DEFAULT NULL
) returns TABLE (
  "trait_id" UUID,
  "trait_clause" TEXT,
  "trait_category" TEXT,
  "split_quality" DOUBLE PRECISION,
  "yes_count" INTEGER,
  "no_count" INTEGER,
  "question_text" TEXT
) language plpgsql
SET
  search_path = public,
  extensions,
  game_logic AS $$
DECLARE
  v_candidate_count INT;
  v_description_embedding vector(384);
BEGIN
  v_candidate_count := jsonb_array_length(p_candidates);
  
  IF v_candidate_count <= 1 THEN
    RETURN;  -- No point asking questions with 0-1 candidates
  END IF;

  -- Get session description embedding for tiebreaker
  SELECT e.embedding INTO v_description_embedding
  FROM game_sessions gs
  JOIN embeddings e ON e.id = gs.embedding_id
  WHERE gs.id = p_session_id;
  
  RETURN QUERY
  WITH candidate_ids AS (
    -- Extract candidate place IDs
    SELECT (c->>'id')::uuid as place_id
    FROM jsonb_array_elements(p_candidates) c
  ),
  trait_counts AS (
    -- Count how many candidates have each trait using place_traits (ground truth)
    SELECT
      t.id as trait_id,
      t.clause,
      t.embedding_id,
      COUNT(pt.place_id) FILTER (WHERE pt.place_id IN (SELECT place_id FROM candidate_ids)) as yes_count
    FROM traits t
    LEFT JOIN place_traits pt ON pt.trait_id = t.id
    WHERE
      -- Don't ask same trait twice
      t.id NOT IN (
        SELECT ga.trait_id
        FROM game_answers ga
        WHERE ga.session_id = p_session_id
          AND ga.trait_id IS NOT NULL
      )
    GROUP BY t.id, t.clause, t.embedding_id
  ),
  trait_splits AS (
    -- Calculate split quality for each trait
    SELECT
      tc.trait_id,
      tc.clause,
      tc.embedding_id,
      'general'::text as category,
      tc.yes_count::INTEGER,
      (v_candidate_count - tc.yes_count)::INTEGER as no_count,
      -- Split quality: 1.0 = perfect 50/50 split, 0.5 = all yes or all no
      (1.0 - ABS(0.5 - (tc.yes_count::float / v_candidate_count)))::DOUBLE PRECISION as split_quality
    FROM trait_counts tc
    WHERE
      -- CRITICAL: Only return traits that actually SPLIT the candidates
      tc.yes_count > 0  -- Some candidates have this trait
      AND tc.yes_count < v_candidate_count  -- Some candidates don't have it
  )
  SELECT
    ts.trait_id,
    ts.clause,
    ts.category,
    ts.split_quality,
    ts.yes_count,
    ts.no_count,
    NULL::TEXT as question_text  -- Will be generated by LLM later
  FROM trait_splits ts
  LEFT JOIN embeddings te ON te.id = ts.embedding_id
  ORDER BY 
    ts.split_quality DESC,
    -- Tiebreaker: prefer traits most similar to description
    CASE WHEN v_description_embedding IS NOT NULL AND te.embedding IS NOT NULL
      THEN (1 - (te.embedding <=> v_description_embedding))
      ELSE 0
    END DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "game_logic"."get_semantic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) owner TO "postgres";


comment ON function "game_logic"."get_semantic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) IS 'Returns traits to generate semantic questions from, ranked by split quality.

Uses place_traits relationship (ground truth) to determine which candidates have which traits.
This is faster and more accurate than embedding similarity.

Split quality formula (from docs/architecture/algorithm.md#question-selection):
- yes_count = count(candidates that have this trait via place_traits)
- no_count = candidate_count - yes_count
- split_quality = 1 - |0.5 - (yes_count / candidate_count)|

Filters by:
1. Not already asked in this session
2. MUST SPLIT CANDIDATES: Only returns traits where some candidates have it and some don''t

Orders by:
1. Split quality (perfect 50/50 split = 1.0)
2. Tiebreaker: trait similarity to description (using embeddings)

Returns: trait info + yes_count, no_count, split_quality for analysis.
Question text is generated on-the-fly by LLM from trait clauses.';

-- --------------------------------------------------------------------------
-- game_logic/functions/questions/update_question_effectiveness_batch.sql
-- --------------------------------------------------------------------------

-- Function: update_question_effectiveness_batch
-- Category: questions
-- Updates game_logic.question_stats based on game performance
CREATE OR REPLACE FUNCTION "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  answer_record RECORD;
  v_stat_id UUID;
  v_question_type question_type;
  precision_gain FLOAT;
  survival INT;
  score_delta FLOAT;
  new_effectiveness_score FLOAT;
  session_was_correct BOOLEAN;
BEGIN
  -- Only update effectiveness for successful/won sessions
  SELECT gs.was_correct INTO session_was_correct
  FROM game_sessions gs
  WHERE gs.id = session_id_param;

  -- Skip update if session was not won
  IF session_was_correct != TRUE THEN
    RETURN;
  END IF;

  FOR answer_record IN
    SELECT
      ga.trait_id,
      ga.geographic_region_id,
      ga.candidates::jsonb->'before_count' AS candidates_before_count,
      ga.candidates::jsonb->'after_count' AS candidates_after_count,
      ga.candidates::jsonb->'correct_survived' AS correct_place_survived
    FROM game_answers ga
    WHERE ga.session_id = session_id_param
      AND (ga.trait_id IS NOT NULL OR ga.geographic_region_id IS NOT NULL)
    ORDER BY ga.created_at ASC
  LOOP
    -- Determine question type
    v_question_type := CASE
      WHEN answer_record.trait_id IS NOT NULL THEN 'semantic'
      WHEN answer_record.geographic_region_id IS NOT NULL THEN 'geographic'
    END;

    -- Find or create game_logic.question_stats entry
    IF v_question_type = 'semantic' THEN
      SELECT id INTO v_stat_id
      FROM game_logic.question_stats
      WHERE trait_id = answer_record.trait_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO game_logic.question_stats (question_type, trait_id)
        VALUES ('semantic', answer_record.trait_id)
        RETURNING id INTO v_stat_id;
      END IF;
    ELSE
      SELECT id INTO v_stat_id
      FROM game_logic.question_stats
      WHERE geographic_region_id = answer_record.geographic_region_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO game_logic.question_stats (question_type, geographic_region_id)
        VALUES ('geographic', answer_record.geographic_region_id)
        RETURNING id INTO v_stat_id;
      END IF;
    END IF;

    -- Calculate precision gain
    precision_gain := (
      (answer_record.candidates_before_count::TEXT::INT - answer_record.candidates_after_count::TEXT::INT)::FLOAT 
      / GREATEST(1.0, answer_record.candidates_before_count::TEXT::INT::FLOAT)
    );

    -- Determine survival
    survival := CASE WHEN answer_record.correct_place_survived::TEXT::BOOLEAN THEN 1 ELSE -1 END;

    -- Calculate score delta
    score_delta := 0.04 * precision_gain * survival;

    -- Apply bonus/penalty adjustments
    IF precision_gain >= 0.30 AND survival = 1 THEN
      score_delta := score_delta + 0.01;
    END IF;

    IF precision_gain < 0.05 THEN
      score_delta := score_delta - 0.02;
    END IF;

    -- Get current effectiveness and calculate new value
    SELECT effectiveness_score INTO new_effectiveness_score
    FROM game_logic.question_stats
    WHERE id = v_stat_id;

    new_effectiveness_score := new_effectiveness_score + score_delta;

    -- Clamp to valid range [0.0, 1.0]
    new_effectiveness_score := LEAST(1.0, GREATEST(0.0, new_effectiveness_score));

    -- Update the stats
    UPDATE game_logic.question_stats
    SET
      times_asked = times_asked + 1,
      effectiveness_score = new_effectiveness_score
    WHERE id = v_stat_id;
  END LOOP;
END;
$$;


ALTER FUNCTION "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "game_logic"."update_question_effectiveness_batch" ("session_id_param" "uuid") IS 'Enhanced effectiveness update for v2 using precision-gain formula from PRD.
Formula:
  precision_gain = (before - after) / greatest(1, before)
  survival = CASE WHEN correct_place_survived THEN 1 ELSE -1 END
  score_delta = 0.04 * precision_gain * survival
  IF precision_gain >= 0.30 AND survival = 1 THEN score_delta += 0.01
  IF precision_gain < 0.05 THEN score_delta -= 0.02
  effectiveness_score = clamp(effectiveness_score + score_delta, 0.0, 1.0)

Also increments times_asked for each question used in the session.';

-- --------------------------------------------------------------------------
-- game_logic/functions/record_game_answer.sql
-- --------------------------------------------------------------------------

-- Function: record_game_answer
-- Category: game
-- Purpose: DRY helper for recording answers in game_answers table
CREATE OR REPLACE FUNCTION "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" UUID,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) returns void language plpgsql
SET
  search_path = public,
  game_logic AS $$
BEGIN
  INSERT INTO game_answers (
    session_id,
    trait_id,
    geographic_region_id,
    answer,
    place_id,
    question_text,
    candidates
  ) VALUES (
    p_session_id,
    p_trait_id,
    p_geographic_region_id,
    p_answer,
    p_place_id,
    p_question_text,
    p_candidates
  );
END;
$$;


ALTER FUNCTION "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" UUID,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "game_logic"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" UUID,
  "p_geographic_region_id" "uuid",
  "p_answer" answer_value,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) IS 'Records answer with candidate snapshot at answer time.

Questions are generated on-the-fly from trait_id or geographic_region_id.';

-- --------------------------------------------------------------------------
-- game_logic/functions/triggers/on_session_approval_regenerate_traits.sql
-- --------------------------------------------------------------------------

-- Trigger Function: on_session_approval_regenerate_traits
-- Schema: game_logic
-- Purpose: Triggers trait update when a session is approved
-- Fires when game_sessions.pending_review changes from TRUE to FALSE
CREATE OR REPLACE FUNCTION "game_logic"."on_session_approval_regenerate_traits" () returns trigger language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when pending_review changes from TRUE to FALSE
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Only update traits if session has a linked place
    IF NEW.place_id IS NOT NULL THEN
      PERFORM game_logic.enqueue_trait_extraction(NEW.place_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."on_session_approval_regenerate_traits" () owner TO "postgres";


comment ON function "game_logic"."on_session_approval_regenerate_traits" () IS 'Trigger function that fires when game_sessions.pending_review changes from TRUE to FALSE.
Calls update_place_traits() to refresh place traits based on all available data.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/apply_metadata_filter.sql
-- --------------------------------------------------------------------------

-- Function: apply_metadata_filter
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN DEFAULT TRUE
) returns BOOLEAN language "plpgsql"
SET
  search_path = public,
  game_logic AS $$
DECLARE
  filter_type TEXT;
  property_paths JSONB;
  operator TEXT;
  value JSONB;
  property_value TEXT;
  path TEXT;
  result BOOLEAN := FALSE;
BEGIN
  filter_type := filter_config->>'filter_type';

  IF filter_type = 'string_in_list_check' THEN
    property_paths := filter_config->'property_paths';
    operator := filter_config->>'operator';
    value := filter_config->'value';

    FOREACH path IN ARRAY ARRAY(SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        IF operator = 'in' AND property_value = ANY(ARRAY(SELECT jsonb_array_elements_text(value))) THEN
          result := TRUE;
          EXIT;
        END IF;
      END IF;
    END LOOP;

  ELSIF filter_type = 'numeric_check' THEN
    property_paths := filter_config->'property_paths';
    operator := filter_config->>'operator';
    value := filter_config->'value';

    FOREACH path IN ARRAY ARRAY(SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        BEGIN
          IF operator = '>=' AND property_value::float >= (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '<=' AND property_value::float <= (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '>' AND property_value::float > (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '<' AND property_value::float < (value->>0)::float THEN
            result := TRUE;
            EXIT;
          END IF;
        EXCEPTION WHEN invalid_text_representation THEN
          -- Property is not numeric, continue to next path
          CONTINUE;
        END;
      END IF;
    END LOOP;

  ELSIF filter_type = 'exists_check' THEN
    property_paths := filter_config->'property_paths';

    FOREACH path IN ARRAY (SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        result := TRUE;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  RETURN result = answer;
END;
$$;


ALTER FUNCTION "game_logic"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN
) owner TO "postgres";


comment ON function "game_logic"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN
) IS 'Applies metadata filters to place descriptors.
Parameters:
- descriptors: JSONB object containing place metadata
- filter_config: JSONB object defining filter type and parameters
- answer: expected result (TRUE for filter should pass, FALSE for inverted)

Returns TRUE if the filter condition matches the expected answer.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/approve_pending_session.sql
-- --------------------------------------------------------------------------

-- Function: approve_pending_session
-- Category: utilities
-- Purpose: Trigger to process approved place submissions
-- When pending_review changes from TRUE to FALSE on places, marks place as approved
CREATE OR REPLACE FUNCTION "game_logic"."approve_pending_session" () returns "trigger" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when pending_review becomes false
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Place is now approved - no additional action needed
    -- The place record already exists with all required data
    NULL;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."approve_pending_session" () owner TO "postgres";


comment ON function "game_logic"."approve_pending_session" () IS 'Trigger function for processing approved place submissions.
When places.pending_review changes from TRUE to FALSE, the place is marked as approved.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/archive_trait_queue_by_place.sql
-- --------------------------------------------------------------------------

-- Function: archive_trait_queue_by_place
-- Category: utilities
-- Purpose: Archive trait extraction queue messages for a given place_id
-- Called by edge function after successful trait extraction
CREATE OR REPLACE FUNCTION "game_logic"."archive_trait_queue_by_place" (
  p_place_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game_logic, extensions, pgmq
AS $$
DECLARE
  v_archived INTEGER := 0;
  v_message RECORD;
BEGIN
  -- Read all messages for this place_id and archive them
  -- Using a short visibility timeout since we're archiving immediately
  FOR v_message IN
    SELECT msg_id, message 
    FROM pgmq.read('trait_extraction', 1, 100)
    WHERE message->>'place_id' = p_place_id::text
  LOOP
    PERFORM pgmq.archive('trait_extraction', v_message.msg_id);
    v_archived := v_archived + 1;
  END LOOP;
  
  RETURN v_archived;
END;
$$;


ALTER FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) OWNER TO "postgres";


-- Grant execute to service_role for edge function access
GRANT EXECUTE ON FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) TO service_role;


COMMENT ON FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) IS 'Archive trait extraction queue messages for a given place_id.

Called by the process-trait-extraction edge function after successful processing.
Archives (not deletes) messages to maintain history for debugging.

Parameters:
- p_place_id: UUID of the place whose messages should be archived

Returns: Number of messages archived.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/build_guess_turn.sql
-- --------------------------------------------------------------------------

-- Function: build_guess_turn
-- Category: utilities
-- Purpose: Pure function to build guess next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "game_logic"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) returns JSONB language "plpgsql" immutable
SET
  search_path = public,
  game_logic AS $$
BEGIN
  RETURN jsonb_build_object(
    'action', 'guess',
    'place_id', p_top_candidate->>'id',
    'place_name', p_top_candidate->>'name',
    'place_lat', (p_top_candidate->>'lat')::float,
    'place_lng', (p_top_candidate->>'lng')::float,
    'candidates', p_candidates
  );
END;
$$;


ALTER FUNCTION "game_logic"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) owner TO "postgres";


comment ON function "game_logic"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) IS 'Pure function to build guess next_turn JSONB.

IMMUTABLE: Same inputs always produce same output (no side effects).

Extracted from decide_next_turn for Single Responsibility Principle.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/build_question_turn.sql
-- --------------------------------------------------------------------------

-- Function: build_question_turn
-- Category: utilities
-- Purpose: Pure function to build question next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "game_logic"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) returns JSONB language plpgsql immutable
SET
  search_path = public,
  game_logic AS $$
BEGIN
  RETURN jsonb_build_object(
    'action', 'question',
    'question_type', p_question_type,
    'question_text', p_question_text,
    'question_reasoning', COALESCE(p_question_reasoning, ''),
    'candidates', p_candidates
  ) || 
  CASE 
    WHEN p_trait_id IS NOT NULL THEN 
      jsonb_build_object('trait_id', p_trait_id)
    WHEN p_geographic_region_id IS NOT NULL THEN 
      jsonb_build_object('geographic_region_id', p_geographic_region_id)
    ELSE '{}'::jsonb
  END;
END;
$$;


ALTER FUNCTION "game_logic"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "game_logic"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" UUID,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) IS 'Pure function to build question next_turn JSONB.

IMMUTABLE: Same inputs always produce same output (no side effects).

Parameters:
- p_question_type: ''semantic'' or ''geographic''
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
- p_question_text: Generated question text
- p_question_reasoning: Optional short explanation of why the question was chosen
- p_candidates: Current candidates array

Returns JSONB structure:
{
  "action": "question",
  "question_type": "semantic" | "geographic",
  "question_text": "Does it have ...?" | "Is it in ...?",
  "question_reasoning": "...",
  "candidates": [...],
  "trait_id": "..." | "geographic_region_id": "..."
}

Extracted from decide_next_turn for Single Responsibility Principle.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/call_llm_api.sql
-- --------------------------------------------------------------------------

-- Function: call_llm_api
-- Category: utilities
-- Purpose: Call LLM via edge function with a prompt
-- Returns: LLM response text
CREATE OR REPLACE FUNCTION "game_logic"."call_llm_api" (
  "p_prompt" "text",
  "p_format" "text" DEFAULT NULL,
  "p_config_prefix" "text" DEFAULT 'llm'
) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
  v_edge_function_url TEXT;
  v_anon_key TEXT;
  v_llm_response TEXT;
  v_request_body JSONB;
  v_llm_model TEXT;
  v_fallback_model TEXT;
  v_llm_options JSONB;
  v_llm_temperature FLOAT;
  v_llm_num_predict INT;
  v_llm_top_p FLOAT;
  v_llm_stop JSONB;
  v_llm_frequency_penalty FLOAT;
  v_llm_presence_penalty FLOAT;
  v_llm_repetition_penalty FLOAT;
  v_json_schema JSONB;
  v_format TEXT;
  v_primary_error TEXT;
BEGIN
  -- Increase statement timeout for slower LLM responses (default 5s is too short)
  PERFORM set_config('statement_timeout', '60s', true);
  -- Increase HTTP timeout (default 5s) so curl waits for LLM
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '60000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '10000');
  -- ============================================================================
  -- CONFIGURATION (from GUC vars or game_logic.config - NO hardcoded secrets)
  -- ============================================================================
  v_edge_function_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF v_edge_function_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  v_edge_function_url := v_edge_function_url || '/functions/v1/call-llm';

  v_anon_key := COALESCE(
    NULLIF(current_setting('app.supabase_anon_key', true), ''),
    get_config_text('runtime.supabase_anon_key')
  );
  
  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_anon_key or runtime.supabase_anon_key';
  END IF;

  -- ============================================================================
  -- FETCH LLM SETTINGS FROM game_logic.config
  -- ============================================================================
  v_llm_model := get_config_text(p_config_prefix || '.model');
  v_fallback_model := get_config_text(p_config_prefix || '.fallback_model', NULL);
  v_llm_temperature := get_config_float(p_config_prefix || '.temperature');
  v_llm_num_predict := get_config_int(p_config_prefix || '.num_predict');
  v_llm_top_p := get_config_float(p_config_prefix || '.top_p');
  v_llm_stop := get_config(p_config_prefix || '.stop');
  v_llm_frequency_penalty := get_config_float(p_config_prefix || '.frequency_penalty');
  v_llm_presence_penalty := get_config_float(p_config_prefix || '.presence_penalty');
  v_llm_repetition_penalty := get_config_float(p_config_prefix || '.repetition_penalty');
  v_json_schema := get_config(p_config_prefix || '.json_schema');
  v_format := COALESCE(p_format, get_config_text(p_config_prefix || '.format'));

  -- Build options object
  v_llm_options := jsonb_build_object(
    'temperature', v_llm_temperature,
    'num_predict', v_llm_num_predict,
    'top_p', v_llm_top_p,
    'stop', v_llm_stop,
    'frequency_penalty', v_llm_frequency_penalty,
    'presence_penalty', v_llm_presence_penalty,
    'repetition_penalty', v_llm_repetition_penalty
  );

  -- Build request body
  v_request_body := jsonb_build_object(
    'prompt', p_prompt,
    'model', v_llm_model,
    'options', v_llm_options
  );
  
  -- Add format if specified (for simple JSON mode)
  IF v_format IS NOT NULL AND v_json_schema IS NULL THEN
    v_request_body := v_request_body || jsonb_build_object('format', v_format);
  END IF;

  -- Add JSON schema for structured outputs (takes precedence over format)
  IF v_json_schema IS NOT NULL THEN
    v_request_body := v_request_body || jsonb_build_object('jsonSchema', v_json_schema);
  END IF;

  RAISE NOTICE 'Calling call-llm at: % with model: %', v_edge_function_url, v_llm_model;

  -- ============================================================================
  -- HTTP CALL TO EDGE FUNCTION (with optional fallback)
  -- ============================================================================
  BEGIN
    SELECT status, content INTO v_status, v_content FROM extensions.http((
      'POST',
      v_edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
      ],
      'application/json',
      v_request_body::text
    )::extensions.http_request);

    IF v_status != 200 THEN
      RAISE EXCEPTION 'LLM call failed with status %: %', v_status, v_content;
    END IF;

    v_llm_response := (v_content::jsonb->>'response')::text;
    RETURN v_llm_response;

  EXCEPTION
    WHEN others THEN
      v_primary_error := SQLERRM;
      
      -- Try fallback model if configured
      IF v_fallback_model IS NOT NULL THEN
        RAISE NOTICE 'Primary model failed (%), trying fallback: %', v_primary_error, v_fallback_model;
        
        v_request_body := jsonb_set(v_request_body, '{model}', to_jsonb(v_fallback_model));
        
        SELECT status, content INTO v_status, v_content FROM extensions.http((
          'POST',
          v_edge_function_url,
          ARRAY[
            extensions.http_header('Content-Type', 'application/json'),
            extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
          ],
          'application/json',
          v_request_body::text
        )::extensions.http_request);

        IF v_status != 200 THEN
          RAISE EXCEPTION 'LLM fallback failed with status %: %', v_status, v_content;
        END IF;

        v_llm_response := (v_content::jsonb->>'response')::text;
        RETURN v_llm_response;
      ELSE
        RAISE EXCEPTION 'LLM API call failed: %', v_primary_error;
      END IF;
  END;
END;
$$;


ALTER FUNCTION "game_logic"."call_llm_api" (
  "p_prompt" "text",
  "p_format" "text",
  "p_config_prefix" "text"
) owner TO "postgres";


comment ON function "game_logic"."call_llm_api" (
  "p_prompt" "text",
  "p_format" "text",
  "p_config_prefix" "text"
) IS 'Call LLM via edge function with config-driven settings and optional fallback.

Parameters:
- p_prompt: The prompt to send
- p_format: Optional format hint (e.g., "json")
- p_config_prefix: Config key prefix (e.g., "llm.trait_extraction", "llm.question")

Configuration keys (from game_logic.config):
- {prefix}.model: Primary OpenRouter model ID
- {prefix}.fallback_model: Optional fallback model if primary fails
- {prefix}.temperature, num_predict, top_p, stop, frequency_penalty, presence_penalty
- {prefix}.json_schema: Structured output schema (if needed)

Fallback: If primary model fails and fallback_model is configured, retries once with fallback.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/check_rate_limit.sql
-- --------------------------------------------------------------------------

-- Category: utilities
-- Purpose: Check and enforce rate limits
-- Spec: openspec/specs/database/spec.md#rate-limiting
CREATE OR REPLACE FUNCTION "game_logic"."check_rate_limit" ("p_action" TEXT) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_user_id UUID;
  v_limit INT;
  v_window_seconds INT;
  v_current_count INT;
  v_config_key TEXT;
BEGIN
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    -- Skip rate limiting in tests
    RETURN;
  END IF;

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_action IS NULL OR trim(p_action) = '' THEN
    RAISE EXCEPTION 'Action cannot be null or empty';
  END IF;

  -- Resolve user from auth context
  v_user_id := auth.uid();

  -- Service role bypasses rate limiting
  IF auth.role() = 'service_role' THEN
    RETURN;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required for rate limited actions';
  END IF;

  -- ============================================================================
  -- GET RATE LIMIT CONFIGURATION
  -- ============================================================================
  -- Rate limits stored in game_logic.config with keys like:
  -- rate_limit.start_game.limit = 10
  -- rate_limit.start_game.window_seconds = 60
  --
  -- Default limits per docs/architecture/operations.md:
  -- start_game: 10 per minute
  -- play_turn: 60 per minute
  -- submit_place: 10 per minute

  v_config_key := 'rate_limit.' || p_action || '.limit';
  
  SELECT value::INT INTO v_limit
  FROM game_logic.config
  WHERE key = v_config_key;
  
  -- Use defaults if not configured
  IF v_limit IS NULL THEN
    CASE p_action
      WHEN 'start_game' THEN v_limit := 10;
      WHEN 'play_turn' THEN v_limit := 60;
      WHEN 'submit_place' THEN v_limit := 10;
      ELSE v_limit := 20; -- Default fallback
    END CASE;
  END IF;

  v_config_key := 'rate_limit.' || p_action || '.window_seconds';
  
  SELECT value::INT INTO v_window_seconds
  FROM game_logic.config
  WHERE key = v_config_key;
  
  -- Default window is 60 seconds (1 minute)
  IF v_window_seconds IS NULL THEN
    v_window_seconds := 60;
  END IF;

  -- ============================================================================
  -- COUNT REQUESTS IN WINDOW
  -- ============================================================================
  SELECT COUNT(*) INTO v_current_count
  FROM game_logic.rate_limit_log
  WHERE user_id = v_user_id
    AND action = p_action
    AND created_at > NOW() - (v_window_seconds || ' seconds')::INTERVAL;

  -- ============================================================================
  -- CHECK LIMIT
  -- ============================================================================
  IF v_current_count >= v_limit THEN
    RAISE EXCEPTION 'rate_limit_exceeded'
      USING DETAIL = format(
        'Rate limit exceeded for action %s: %s requests in %s seconds (limit: %s)',
        p_action, v_current_count, v_window_seconds, v_limit
      ),
      HINT = 'Please wait before retrying';
  END IF;

  -- ============================================================================
  -- LOG REQUEST (allowed)
  -- ============================================================================
  INSERT INTO game_logic.rate_limit_log (user_id, action, created_at)
  VALUES (v_user_id, p_action, NOW());

  -- Return void if allowed
  RETURN;
END;
$$;


ALTER FUNCTION "game_logic"."check_rate_limit" (TEXT) owner TO "postgres";


comment ON function "game_logic"."check_rate_limit" (TEXT) IS 'Check and enforce rate limits for RPC functions.

Parameters:
- p_action: The action being rate limited (start_game, play_turn, submit_place)

Behavior:
1. Count requests in rate_limit_log for (user_id, action) within time window
2. If count >= limit, raise exception with rate_limit_exceeded error
3. If allowed, insert new entry to rate_limit_log
4. Return void if allowed

Rate limits (from docs/architecture/operations.md):
- start_game: 10 per minute
- play_turn: 60 per minute  
- submit_place: 10 per minute

Configuration:
Limits can be overridden via game_logic.config table:
- rate_limit.<action>.limit: Max requests
- rate_limit.<action>.window_seconds: Time window in seconds

Security: SECURITY DEFINER to access game_logic.config and rate_limit_log. Uses auth.uid() internally; service_role bypasses limits.

Error codes:
- rate_limit_exceeded: Returns 429 status to frontend';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/create_place_with_traits.sql
-- --------------------------------------------------------------------------

-- Function: create_place_with_traits
-- Category: utilities
-- Purpose: Create a place record with traits and embedding from Nominatim data
CREATE OR REPLACE FUNCTION "game_logic"."create_place_with_traits" (
  "p_osm_id" TEXT,
  "p_nominatim_data" JSONB,
  "p_traits" JSONB,
  "p_is_curated" BOOLEAN DEFAULT FALSE
) returns UUID language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place_id UUID;
  v_name TEXT;
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
  v_geojson JSONB;
  v_trait_clauses TEXT[];
  v_combined_text TEXT;
  v_embedding_id UUID;
  v_trait_id UUID;
  v_trait_clause TEXT;
  v_trait_embedding_id UUID;
BEGIN
  -- ============================================================================
  -- EXTRACT PLACE FIELDS
  -- ============================================================================
  v_name := COALESCE(
    p_nominatim_data->'namedetails'->>'name:en',
    p_nominatim_data->>'name',
    p_nominatim_data->>'display_name'
  );
  v_lat := (p_nominatim_data->>'lat')::DOUBLE PRECISION;
  v_lng := (p_nominatim_data->>'lon')::DOUBLE PRECISION;
  v_geojson := p_nominatim_data->'geojson';

  -- ============================================================================
  -- EXTRACT TRAIT CLAUSES FOR EMBEDDING
  -- ============================================================================
  IF p_traits IS NOT NULL AND jsonb_array_length(p_traits) > 0 THEN
    SELECT array_agg(DISTINCT t)
    INTO v_trait_clauses
    FROM jsonb_array_elements_text(p_traits) AS t
    WHERE t IS NOT NULL;
  END IF;

  -- ============================================================================
  -- GENERATE EMBEDDING FROM COMBINED TRAIT CLAUSES
  -- ============================================================================
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    v_combined_text := array_to_string(v_trait_clauses, '. ');
    -- Use 'passage' since place traits are documents matched against user queries
    v_embedding_id := get_embedding(v_combined_text, 'passage');
  END IF;

  -- ============================================================================
  -- CREATE PLACE RECORD
  -- ============================================================================
  -- Note: add_place expects p_pending_review, we invert p_is_curated
  -- Curated places (is_curated=TRUE) don't need review (pending_review=FALSE)
  v_place_id := game_logic.add_place(
    v_name,
    p_osm_id,
    v_lat::NUMERIC,
    v_lng::NUMERIC,
    v_geojson,
    NOT p_is_curated  -- invert: curated places don't need review
  );

  IF v_embedding_id IS NOT NULL THEN
    UPDATE places
    SET embedding_id = v_embedding_id
    WHERE id = v_place_id;
  END IF;

  -- ============================================================================
  -- CREATE TRAITS AND LINK TO PLACE
  -- ============================================================================
  IF p_traits IS NOT NULL AND jsonb_array_length(p_traits) > 0 THEN
    FOR v_trait_clause IN
      SELECT DISTINCT t
      FROM jsonb_array_elements_text(p_traits) AS t
      WHERE t IS NOT NULL
    LOOP
      -- Generate embedding for trait clause (use 'passage' since traits are matched against queries)
      v_trait_embedding_id := get_embedding(v_trait_clause, 'passage');

      -- Insert trait with generated UUID (deduplication via embedding_id)
      INSERT INTO traits (id, clause, embedding_id)
      VALUES (gen_random_uuid(), v_trait_clause, v_trait_embedding_id)
      ON CONFLICT (embedding_id) DO UPDATE SET
        clause = EXCLUDED.clause
      RETURNING id INTO v_trait_id;

      -- Link trait to place
      INSERT INTO place_traits (place_id, trait_id)
      VALUES (v_place_id, v_trait_id)
      ON CONFLICT (place_id, trait_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN v_place_id;
END;
$$;


ALTER FUNCTION "game_logic"."create_place_with_traits" (TEXT, JSONB, JSONB, BOOLEAN) owner TO "postgres";


comment ON function "game_logic"."create_place_with_traits" (TEXT, JSONB, JSONB, BOOLEAN) IS 'Create a place record with traits and embedding.

Parameters:
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364")
- p_nominatim_data: JSONB from fetch_nominatim_place()
- p_traits: JSONB array from extract_traits_from_nominatim()
- p_is_curated: Whether this is a curated place (default FALSE)

Process:
1. Extract name, lat, lng, geojson from Nominatim data
2. Generate embedding from combined trait clauses for place embedding
3. Create place record via add_place()
4. Generate embeddings for individual traits and link to place

Returns: UUID of created place';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/enqueue_trait_extraction.sql
-- --------------------------------------------------------------------------

-- Function: enqueue_trait_extraction
-- Category: utilities
-- Purpose: Enqueue a trait extraction job via pgmq + pg_net fire-and-forget
CREATE OR REPLACE FUNCTION "game_logic"."enqueue_trait_extraction" (
  p_place_id UUID
) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions,
  pgmq AS $$
DECLARE
  v_url TEXT;
  v_auth_token TEXT;
  v_headers JSONB;
  v_body JSONB;
  v_message_id BIGINT;
BEGIN
  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_place_id IS NULL THEN
    RAISE EXCEPTION 'Place ID cannot be null';
  END IF;

  -- ============================================================================
  -- ENQUEUE TO PGMQ (for durability)
  -- ============================================================================
  -- Message stays in queue until explicitly deleted after successful processing
  SELECT pgmq.send(
    'trait_extraction',
    jsonb_build_object(
      'place_id', p_place_id,
      'enqueued_at', now()
    )
  ) INTO v_message_id;

  -- ============================================================================
  -- FIRE PG_NET REQUEST (fire-and-forget for immediate processing)
  -- ============================================================================
  -- Build Edge Function URL
  v_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    game_logic.get_config_text('runtime.supabase_url')
  );
  
  IF v_url IS NULL THEN
    RAISE WARNING 'Missing configuration: app.supabase_url or runtime.supabase_url. Trait extraction will be skipped.';
    RETURN;
  END IF;
  
  v_url := v_url || '/functions/v1/process-trait-extraction';
  
  -- Get service role key for authentication
  v_auth_token := COALESCE(
    NULLIF(current_setting('app.service_role_key', true), ''),
    game_logic.get_config_text('runtime.supabase_service_role_key')
  );
  
  IF v_auth_token IS NULL OR v_auth_token = '' THEN
    RAISE WARNING 'Missing configuration: app.service_role_key or runtime.supabase_service_role_key. Trait extraction will be skipped.';
    RETURN;
  END IF;
  
  -- Build request headers
  v_headers := jsonb_build_object(
    'Authorization', 'Bearer ' || v_auth_token,
    'Content-Type', 'application/json'
  );
  
  -- Build request body for generic async RPC invoker
  v_body := jsonb_build_object(
    'function_name', 'update_place_traits',
    'params', jsonb_build_object('p_place_id', p_place_id)
  );
  
  -- Fire HTTP request (fire-and-forget, no response collection)
  -- Signature: net.http_post(url, body, params, headers, timeout_milliseconds)
  -- Using 30s timeout to allow for Nominatim + LLM + embeddings calls
  PERFORM net.http_post(
    v_url,           -- url
    v_body,          -- body (jsonb)
    '{}'::jsonb,     -- params (empty)
    v_headers,       -- headers
    30000            -- timeout_milliseconds (30 seconds)
  );

EXCEPTION
  WHEN others THEN
    -- Log error but don't fail - async processing is best-effort
    RAISE WARNING 'enqueue_trait_extraction failed for place %: %', p_place_id, SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."enqueue_trait_extraction" (UUID) owner TO "postgres";


comment ON function "game_logic"."enqueue_trait_extraction" (UUID) IS 'Enqueue a trait extraction job for async processing.

Two-phase async pattern:
1. pgmq.send() - Durable queue for guaranteed delivery
2. pg_net.http_post() - Fire-and-forget for immediate processing

The pgmq message provides durability - if the edge function fails,
pg_cron backup processor will pick up orphaned messages.

Parameters:
- p_place_id: UUID of place to extract traits for

Returns immediately - trait extraction happens asynchronously.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/enrich_place_on_approval.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place_on_approval
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."enrich_place_on_approval" () returns "trigger" language "plpgsql"
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when pending_review becomes FALSE
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Run enrichment
    PERFORM enrich_place(NEW.id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place_on_approval" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/enrich_place_on_session_complete.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place_on_session_complete
-- Category: utilities
-- Purpose: Trigger function that enriches place with learned traits when a session completes
CREATE OR REPLACE FUNCTION "game_logic"."enrich_place_on_session_complete" () returns "trigger" language "plpgsql"
SET
  search_path = public,
  game_logic AS $$
BEGIN
  -- Only fire when was_correct becomes TRUE
  IF NEW.was_correct = TRUE AND (OLD.was_correct IS NULL OR OLD.was_correct = FALSE) THEN
    -- Enqueue trait extraction asynchronously (pg_net fire-and-forget)
    PERFORM enqueue_trait_extraction(NEW.place_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "game_logic"."enrich_place_on_session_complete" () owner TO "postgres";


comment ON function "game_logic"."enrich_place_on_session_complete" () IS 'Trigger function that enriches a place when a game session completes successfully.

When was_correct becomes TRUE, calls update_place_traits() to refresh all traits
using nominatim data, session descriptions, and game answers.

This enables the game to learn about places from successful games.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/extract_traits_from_nominatim.sql
-- --------------------------------------------------------------------------

-- Function: extract_traits_from_nominatim
-- Category: utilities
-- Purpose: Extract basic traits from Nominatim data (rule-based only)
CREATE OR REPLACE FUNCTION "game_logic"."extract_traits_from_nominatim" ("p_nominatim_data" JSONB) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_traits JSONB := '[]'::jsonb;
  v_address JSONB;
BEGIN
  v_address := COALESCE(p_nominatim_data->'address', '{}'::jsonb);

  -- Add class as trait
  IF p_nominatim_data->>'class' IS NOT NULL THEN
    v_traits := v_traits || to_jsonb(initcap(p_nominatim_data->>'class'));
  END IF;
  
  -- Add type as trait
  IF p_nominatim_data->>'type' IS NOT NULL THEN
    v_traits := v_traits || to_jsonb(initcap(replace(p_nominatim_data->>'type', '_', ' ')));
  END IF;

  -- Add country as trait
  IF v_address->>'country' IS NOT NULL THEN
    v_traits := v_traits || to_jsonb(v_address->>'country');
  END IF;

  RETURN v_traits;
END;
$$;


ALTER FUNCTION "game_logic"."extract_traits_from_nominatim" (JSONB) owner TO "postgres";


comment ON function "game_logic"."extract_traits_from_nominatim" (JSONB) IS 'Extract basic traits from Nominatim data (rule-based only).

Returns class, type, and country as initial traits.
LLM-based trait extraction is handled by update_place_traits().';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/fetch_nominatim_place.sql
-- --------------------------------------------------------------------------

-- Function: fetch_nominatim_place
-- Category: utilities
-- Purpose: Fetch place data from Nominatim by OSM ID
CREATE OR REPLACE FUNCTION "game_logic"."fetch_nominatim_place" ("p_osm_id" TEXT) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
  v_osm_type TEXT;
  v_osm_id_num BIGINT;
  v_nominatim_data JSONB;
BEGIN
  -- ============================================================================
  -- PARSE OSM ID (format: "way/123456" or "node/123456" or "relation/123456")
  -- ============================================================================
  v_osm_type := split_part(p_osm_id, '/', 1);
  v_osm_id_num := split_part(p_osm_id, '/', 2)::BIGINT;
  
  IF v_osm_type NOT IN ('node', 'way', 'relation') THEN
    RAISE EXCEPTION 'Invalid OSM ID format. Expected node/way/relation prefix: %', p_osm_id;
  END IF;

  -- ============================================================================
  -- CALL NOMINATIM
  -- ============================================================================
  PERFORM set_config('statement_timeout', '60s', true);
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '60000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '15000');

  RAISE NOTICE 'Calling Nominatim lookup for: %', p_osm_id;

  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'GET',
    format(
      'https://nominatim.openstreetmap.org/lookup?osm_ids=%s%s&format=json&extratags=1&addressdetails=1&namedetails=1&polygon_geojson=1',
      upper(left(v_osm_type, 1)),  -- N, W, or R
      v_osm_id_num
    ),
    ARRAY[
      extensions.http_header('User-Agent', '10x-mapmaster/1.0'),
      extensions.http_header('Accept', 'application/json')
    ],
    NULL,
    NULL
  )::extensions.http_request);

  IF v_status != 200 THEN
    RAISE EXCEPTION 'Nominatim lookup failed with status %: %', v_status, v_content;
  END IF;

  -- Parse response (returns array, take first result)
  v_nominatim_data := (v_content::jsonb)->0;
  
  IF v_nominatim_data IS NULL THEN
    RAISE EXCEPTION 'Place not found in Nominatim: %', p_osm_id;
  END IF;

  RETURN v_nominatim_data;
END;
$$;


ALTER FUNCTION "game_logic"."fetch_nominatim_place" (TEXT) owner TO "postgres";


comment ON function "game_logic"."fetch_nominatim_place" (TEXT) IS 'Fetch place data from Nominatim by OSM ID.

Parameters:
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364", "node/123456", "relation/789")

Returns: JSONB with Nominatim response including:
- name, display_name, lat, lon
- namedetails (localized names)
- address (country, city, etc.)
- extratags (height, wikipedia, etc.)
- geojson (geometry)

Raises exception if:
- Invalid OSM ID format
- Nominatim request fails
- Place not found';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/generate_embedding.sql
-- --------------------------------------------------------------------------

-- Function: generate_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."generate_embedding" (
  "p_text" "text",
  "p_input_type" "text" DEFAULT 'query'  -- 'query' for searches, 'passage' for documents/traits
) returns "extensions"."vector" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
  edge_function_url TEXT;
  validated_text TEXT;
  embedding_vector vector(384);
  v_anon_key TEXT;
  v_input_type TEXT;
BEGIN
  -- Validate input_type (must be 'query' or 'passage')
  v_input_type := COALESCE(p_input_type, 'query');
  IF v_input_type NOT IN ('query', 'passage') THEN
    RAISE EXCEPTION 'Invalid input_type: %. Must be ''query'' or ''passage''', v_input_type;
  END IF;
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    RETURN array_fill(0.0, ARRAY[384])::vector(384);
  END IF;

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================

  -- Validate text input (max 1000 chars, min 1 char after trim)
  validated_text := validate_user_input(p_text, 1000, 'embedding_text');

  -- ============================================================================
  -- CONFIGURATION RETRIEVAL (from GUC vars or game_logic.config - NO hardcoded secrets)
  -- ============================================================================

  -- Get Supabase URL from settings
  edge_function_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF edge_function_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  edge_function_url := edge_function_url || '/functions/v1/generate-embedding';

  -- Get anon key from settings
  v_anon_key := COALESCE(
    NULLIF(current_setting('app.supabase_anon_key', true), ''),
    get_config_text('runtime.supabase_anon_key')
  );
  
  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_anon_key or runtime.supabase_anon_key';
  END IF;

  RAISE NOTICE 'Calling generate-embedding at: %', edge_function_url;

  -- ============================================================================
  -- EDGE FUNCTION CALL (SYNCHRONOUS HTTP)
  -- ============================================================================

  -- Make synchronous HTTP request using http extension
  -- Note: Select specific columns to avoid TupleDesc resource leak
  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'POST',
    edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    jsonb_build_object('text', validated_text, 'inputType', v_input_type)::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', v_status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================

  -- Check for success
  IF v_status != 200 THEN
    RAISE EXCEPTION 'Embedding generation failed with status %: %', v_status, v_content;
  END IF;

  -- Parse the embedding from response
  embedding_vector := (v_content::jsonb->>'embedding')::vector(384);

  IF embedding_vector IS NULL THEN
    RAISE EXCEPTION 'Response did not contain valid embedding: %', response.content;
  END IF;

  RETURN embedding_vector;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'Embedding generation failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."generate_embedding" ("p_text" "text", "p_input_type" "text") owner TO "postgres";


comment ON function "game_logic"."generate_embedding" ("p_text" "text", "p_input_type" "text") IS 'Generates a 384-dimensional embedding vector for the given text with input validation.
Parameters:
- p_text: text to embed (validated: 1-1000 chars, no control chars)
- p_input_type: ''query'' for user searches, ''passage'' for documents/traits (default: ''query'')

E5 Model Prefixes:
- E5 models use asymmetric retrieval training
- ''query'' inputs are prefixed with "query: " (for user descriptions being searched)
- ''passage'' inputs are prefixed with "passage: " (for traits being matched against)
- This asymmetric prefixing is critical for optimal matching quality

Security:
- Validates input via validate_user_input()
- Prevents injection attacks via control character detection
- Enforces length limits
- Uses Authorization header with anon key

Configuration:
- Uses current_setting(''app.supabase_url'', true) with fallback to ''http://host.docker.internal:54321''
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Process:
1. Validates input text and input_type
2. Calls edge function (generate-embedding) via synchronous http extension
3. Parses and returns vector(384)

Error handling:
- Raises exception on validation failure
- Raises exception on HTTP error
- Raises exception on parsing failure

Technical:
- Uses http extension (synchronous) for reliability in local and production environments
- Authorization header required for edge function infrastructure';


-- Function Permissions: INTERNAL ONLY
-- This function should ONLY be called by other database functions (start_game, etc.)
-- NOT directly from the frontend, to prevent API quota abuse.
-- Rate limiting is enforced at the entry points (start_game, etc.)
REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  public;


REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  anon;


REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  authenticated;


-- Only postgres role and service_role can execute
GRANT
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT) TO postgres;


GRANT
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT) TO service_role;

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/generate_question_text.sql
-- --------------------------------------------------------------------------

-- Function: generate_question_text
-- Category: utilities
-- Purpose: Generate natural language question text using LLM via call_llm_api
CREATE OR REPLACE FUNCTION "game_logic"."generate_question_text" (
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT DEFAULT 'en',
  p_user_description TEXT DEFAULT ''
) returns TEXT language plpgsql security definer
SET
  search_path = public,
  extensions,
  game_logic AS $$
DECLARE
  v_trait_clause TEXT;
  v_region_name TEXT;
  v_prompt_template TEXT;
  v_prompt TEXT;
  v_llm_response TEXT;
  v_question_text TEXT;
BEGIN
  -- Get trait or region context and build prompt from config template
  IF p_trait_id IS NOT NULL THEN
    SELECT clause INTO v_trait_clause
    FROM traits
    WHERE id = p_trait_id;
    
    IF v_trait_clause IS NULL THEN
      RAISE EXCEPTION 'Trait % not found in traits table', p_trait_id;
    END IF;
    
    v_prompt_template := get_config_text('llm.question.trait_prompt');
    v_prompt := replace(v_prompt_template, '{trait_clause}', v_trait_clause);
    v_prompt := replace(v_prompt, '{language_code}', p_language_code);
    v_prompt := replace(v_prompt, '{user_description}', COALESCE(p_user_description, ''));
    
  ELSIF p_region_id IS NOT NULL THEN
    SELECT name INTO v_region_name
    FROM geographic_regions
    WHERE id = p_region_id;
    
    IF v_region_name IS NULL THEN
      RAISE EXCEPTION 'Geographic region % not found', p_region_id;
    END IF;
    
    v_prompt_template := get_config_text('llm.question.region_prompt');
    v_prompt := replace(v_prompt_template, '{region_name}', v_region_name);
    v_prompt := replace(v_prompt, '{language_code}', p_language_code);
    v_prompt := replace(v_prompt, '{user_description}', COALESCE(p_user_description, ''));
    
  ELSE
    RAISE EXCEPTION 'Either trait_id or region_id must be provided';
  END IF;
  
  -- Call LLM via call_llm_api with question-specific config - no fallback, fail if LLM fails
  v_llm_response := call_llm_api(v_prompt, NULL, 'llm.question');
  v_question_text := trim(v_llm_response);
  
  IF v_question_text IS NULL OR v_question_text = '' THEN
    RAISE EXCEPTION 'LLM returned empty response for question generation';
  END IF;
  
  -- Ensure question ends with question mark
  IF v_question_text NOT LIKE '%?' THEN
    v_question_text := v_question_text || '?';
  END IF;
  
  RETURN v_question_text;
END;
$$;


ALTER FUNCTION "game_logic"."generate_question_text" (
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT,
  p_user_description TEXT
) owner TO "postgres";


comment ON function "game_logic"."generate_question_text" (
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT,
  p_user_description TEXT
) IS 'Generate natural language question text using LLM.

Parameters:
- p_trait_id: Trait ID for semantic questions (optional)
- p_region_id: Geographic region ID for geographic questions (optional)
- p_language_code: Language code for the question output
- p_user_description: Original user description for context

Returns: Natural language question text in the requested language.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/geo_region_for.sql
-- --------------------------------------------------------------------------

-- Function: geo_region_for
-- Category: utilities
-- Purpose: Map geographic feature values to standard bounding boxes (SRID 4326)
-- Returns JSONB with bbox array [min_lat, max_lat, min_lng, max_lng]
CREATE OR REPLACE FUNCTION "game_logic"."geo_region_for" ("p_feature_value" "text") returns "jsonb" language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_bbox JSONB;
BEGIN
  -- Map geographic feature values to standard bounding boxes
  -- Format: [min_lat, max_lat, min_lng, max_lng] in SRID 4326
  v_bbox := CASE LOWER(p_feature_value)
    -- Continents
    WHEN 'europe' THEN jsonb_build_object('bbox', jsonb_build_array(35, 71, -10, 40))
    WHEN 'asia' THEN jsonb_build_object('bbox', jsonb_build_array(-10, 77, 26, 180))
    WHEN 'americas' THEN jsonb_build_object('bbox', jsonb_build_array(-56, 85, -170, -35))
    WHEN 'africa' THEN jsonb_build_object('bbox', jsonb_build_array(-35, 37, -18, 52))
    WHEN 'oceania' THEN jsonb_build_object('bbox', jsonb_build_array(-47, -10, 113, 180))
    WHEN 'north america' THEN jsonb_build_object('bbox', jsonb_build_array(15, 85, -170, -50))
    WHEN 'south america' THEN jsonb_build_object('bbox', jsonb_build_array(-56, 13, -82, -35))
    
    -- European countries
    WHEN 'france' THEN jsonb_build_object('bbox', jsonb_build_array(41.5, 51.5, -8, 8))
    WHEN 'uk' THEN jsonb_build_object('bbox', jsonb_build_array(50, 59, -8, 2))
    WHEN 'united kingdom' THEN jsonb_build_object('bbox', jsonb_build_array(50, 59, -8, 2))
    WHEN 'germany' THEN jsonb_build_object('bbox', jsonb_build_array(47, 56, 6, 16))
    WHEN 'italy' THEN jsonb_build_object('bbox', jsonb_build_array(36, 47, 6, 19))
    WHEN 'spain' THEN jsonb_build_object('bbox', jsonb_build_array(36, 44, -10, 4))
    WHEN 'portugal' THEN jsonb_build_object('bbox', jsonb_build_array(37, 42, -10, -6))
    WHEN 'netherlands' THEN jsonb_build_object('bbox', jsonb_build_array(50.5, 53.5, 3, 8))
    WHEN 'belgium' THEN jsonb_build_object('bbox', jsonb_build_array(49.5, 51.5, 2, 6))
    WHEN 'switzerland' THEN jsonb_build_object('bbox', jsonb_build_array(45, 48, 5, 11))
    WHEN 'austria' THEN jsonb_build_object('bbox', jsonb_build_array(46.5, 49, 9, 17))
    WHEN 'czech republic' THEN jsonb_build_object('bbox', jsonb_build_array(48, 51, 12, 19))
    WHEN 'poland' THEN jsonb_build_object('bbox', jsonb_build_array(49, 54, 14, 24))
    WHEN 'sweden' THEN jsonb_build_object('bbox', jsonb_build_array(55, 70, 11, 25))
    WHEN 'norway' THEN jsonb_build_object('bbox', jsonb_build_array(58, 71, 4, 32))
    WHEN 'denmark' THEN jsonb_build_object('bbox', jsonb_build_array(54, 58, 8, 16))
    WHEN 'greece' THEN jsonb_build_object('bbox', jsonb_build_array(35, 42, 19, 29))
    WHEN 'hungary' THEN jsonb_build_object('bbox', jsonb_build_array(45.5, 48.5, 16, 23))
    WHEN 'romania' THEN jsonb_build_object('bbox', jsonb_build_array(43.5, 48.5, 20, 30))
    WHEN 'ireland' THEN jsonb_build_object('bbox', jsonb_build_array(51.5, 55.5, -11, -5))
    WHEN 'scotland' THEN jsonb_build_object('bbox', jsonb_build_array(55, 59, -8, -2))
    WHEN 'wales' THEN jsonb_build_object('bbox', jsonb_build_array(51.5, 53.5, -5, -2))
    WHEN 'england' THEN jsonb_build_object('bbox', jsonb_build_array(50, 56, -6, 2))
    
    -- Default: return NULL if feature value not recognized
    ELSE NULL
  END;

  RETURN v_bbox;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Error in geo_region_for: %', SQLERRM;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "game_logic"."geo_region_for" ("p_feature_value" "text") owner TO "postgres";


comment ON function "game_logic"."geo_region_for" ("p_feature_value" "text") IS 'Maps geographic feature values to standard bounding boxes (SRID 4326).

Parameters:
- p_feature_value: Geographic feature value (e.g., "Europe", "France", "UK")

Returns JSONB object with bbox array:
{
  "bbox": [min_lat, max_lat, min_lng, max_lng]
}

Supported values:
- Continents: Europe, Asia, Americas, Africa, Oceania, North America, South America
- European countries: France, UK, Germany, Italy, Spain, Portugal, Netherlands, Belgium, 
  Switzerland, Austria, Czech Republic, Poland, Sweden, Norway, Denmark, Greece, Hungary, 
  Romania, Ireland, Scotland, Wales, England

Returns NULL if feature value not recognized.

Used by generate_question to set geographic_region when question_type=''geographic''.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/get_config.sql
-- --------------------------------------------------------------------------

-- Function: get_config
-- Category: utilities
-- Purpose: Retrieve configuration value from game_logic.config
CREATE OR REPLACE FUNCTION "game_logic"."get_config" ("p_key" TEXT) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  RETURN v_value;
END;
$$;


-- Helper function to get numeric config value (FLOAT)
CREATE OR REPLACE FUNCTION "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT DEFAULT 0.0) returns FLOAT language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default::TEXT)::FLOAT;
END;
$$;


-- Helper function to get integer config value
CREATE OR REPLACE FUNCTION "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER DEFAULT 0) returns INTEGER language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default::TEXT)::INTEGER;
END;
$$;


-- Helper function to get text config value
CREATE OR REPLACE FUNCTION "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT DEFAULT NULL) returns TEXT language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default);
END;
$$;


ALTER FUNCTION "game_logic"."get_config" ("p_key" TEXT) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT) owner TO "postgres";


comment ON function "game_logic"."get_config" ("p_key" TEXT) IS 'Retrieve configuration value from game_logic.config as JSONB.
Returns NULL if key not found.';


comment ON function "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT) IS 'Retrieve configuration value as FLOAT with default.';


comment ON function "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER) IS 'Retrieve configuration value as INTEGER with default.';


comment ON function "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT) IS 'Retrieve configuration value as TEXT with default.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/get_embedding.sql
-- --------------------------------------------------------------------------

-- Function: get_embedding
-- Category: utilities
-- Gets existing embedding or creates a new one for the given text
CREATE OR REPLACE FUNCTION "game_logic"."get_embedding" (
  "p_text" "text",
  "p_input_type" "text" DEFAULT 'query'  -- 'query' for searches, 'passage' for documents/traits
) returns UUID language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_embedding_id uuid;
  v_embedding vector(384);
BEGIN
  -- First, check if embedding already exists
  SELECT id INTO v_embedding_id
  FROM embeddings
  WHERE source_text = p_text;
  
  -- If found, return existing ID
  IF v_embedding_id IS NOT NULL THEN
    RETURN v_embedding_id;
  END IF;

  -- Generate new embedding with the specified input type
  v_embedding := generate_embedding(p_text, p_input_type);

  -- Store new embedding (use ON CONFLICT for race condition safety)
  INSERT INTO embeddings (source_text, embedding)
  VALUES (p_text, v_embedding)
  ON CONFLICT (source_text) DO UPDATE SET source_text = EXCLUDED.source_text
  RETURNING id INTO v_embedding_id;

  RETURN v_embedding_id;
END;
$$;


ALTER FUNCTION "game_logic"."get_embedding" ("p_text" "text", "p_input_type" "text") owner TO "postgres";


comment ON function "game_logic"."get_embedding" ("p_text" "text", "p_input_type" "text") IS 'Gets existing embedding for the given text or creates a new one.

Parameters:
- p_text: text to embed
- p_input_type: ''query'' for user searches, ''passage'' for documents/traits (default: ''query'')

Process:
1. Return existing embedding_id when source_text matches
2. Otherwise call generate_embedding with appropriate input_type
3. Return embedding UUID

Note: The input_type affects the E5 model prefix used during embedding generation.
Cached embeddings are keyed by source_text only, so ensure consistent input_type usage per text.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/get_max_turns.sql
-- --------------------------------------------------------------------------

-- Function: get_max_turns
-- Category: utilities
-- Purpose: Get max_turns setting from game_logic.config (DRY helper)
CREATE OR REPLACE FUNCTION "game_logic"."get_max_turns" () returns INTEGER language sql stable security definer
SET
  search_path = public,
  game_logic AS $$
  SELECT get_config_int('game.max_turns', 5);
$$;


ALTER FUNCTION "game_logic"."get_max_turns" () owner TO "postgres";


comment ON function "game_logic"."get_max_turns" () IS 'Get max_turns from game_logic.config table.
Returns 5 if setting not found.
Marked STABLE for query optimization.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/http_call_edge_function.sql
-- --------------------------------------------------------------------------

-- Function: http_call_edge_function
-- Category: utilities
-- Purpose: Call Supabase Edge Functions from database using pg_net extension
CREATE OR REPLACE FUNCTION "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT DEFAULT 'POST',
  p_headers JSONB DEFAULT '{}',
  p_body JSONB DEFAULT '{}'
) returns JSONB language plpgsql security definer
SET
  search_path = public,
  extensions,
  game_logic AS $$
DECLARE
  v_url TEXT;
  v_auth_token TEXT;
  v_response_body TEXT;
  v_response_status INT;
  v_result JSONB;
BEGIN
  -- Build Edge Function URL (from GUC vars or game_logic.config - NO hardcoded values)
  v_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF v_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  v_url := v_url || '/functions/v1/' || p_function_name;
  
  -- Get service role key for authentication (NO hardcoded secrets)
  v_auth_token := COALESCE(
    NULLIF(current_setting('app.service_role_key', true), ''),
    get_config_text('runtime.supabase_service_role_key')
  );
  
  IF v_auth_token IS NULL OR v_auth_token = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.service_role_key or runtime.supabase_service_role_key';
  END IF;
  
  -- Add authorization header
  p_headers := p_headers || jsonb_build_object(
    'Authorization', 'Bearer ' || v_auth_token,
    'Content-Type', 'application/json'
  );
  
  -- Make HTTP request using pg_net
  PERFORM net.http_post(
    url := v_url,
    headers := p_headers,
    body := jsonb_build_object('data', p_body)::text
  );
  
  -- Wait for response
  SELECT 
    body,
    status
  INTO v_response_body, v_response_status
  FROM net.http_collect_response(
    (SELECT id FROM net.http_request ORDER BY created_at DESC LIMIT 1)
  );
  
  -- Check for HTTP errors
  IF v_response_status < 200 OR v_response_status >= 300 THEN
    RAISE EXCEPTION 'Edge function call failed: status %, body: %', v_response_status, v_response_body;
  END IF;
  
  -- Parse and return JSON response
  BEGIN
    v_result := v_response_body::jsonb;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'Edge function returned invalid JSON: %', v_response_body;
  END;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT,
  p_headers JSONB,
  p_body JSONB
) owner TO "postgres";


comment ON function "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT,
  p_headers JSONB,
  p_body JSONB
) IS 'Call Supabase Edge Functions from database using pg_net extension.

Requires pg_net extension and app settings:
- app.supabase_url: Supabase project URL
- app.service_role_key: Service role key for authentication

Parameters:
- p_function_name: Name of edge function (without path)
- p_method: HTTP method (default: POST)
- p_headers: Additional headers as JSONB
- p_body: Request body as JSONB

Returns: JSONB response from edge function

Raises exception on HTTP errors or invalid JSON response.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/is_installed.sql
-- --------------------------------------------------------------------------

-- Helper: is_installed
-- Purpose: Test helper to check extension presence (pgTAP compatible signature)
-- Note: Ignores the description argument; returns true if extension exists.
CREATE OR REPLACE FUNCTION "game_logic"."is_installed" (p_extname TEXT, p_description TEXT) returns BOOLEAN language sql stable
SET
  search_path = public,
  game_logic AS $$
  SELECT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = p_extname
  );
$$;

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/process_orphaned_trait_jobs.sql
-- --------------------------------------------------------------------------

-- Function: process_orphaned_trait_jobs
-- Category: utilities
-- Purpose: Backup processor for orphaned trait extraction queue messages
-- Called by pg_cron every 60 seconds to process messages that weren't handled by the primary async path
CREATE OR REPLACE FUNCTION "game_logic"."process_orphaned_trait_jobs" ()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game_logic, extensions, pgmq
AS $$
DECLARE
  v_message RECORD;
  v_processed INTEGER := 0;
  v_place_id UUID;
BEGIN
  -- Read up to 5 messages with 300 second visibility timeout
  -- Using 5 minutes to prevent race condition with 60-second cron interval
  -- Messages become visible again if not processed within timeout
  FOR v_message IN
    SELECT * FROM pgmq.read('trait_extraction', 300, 5)
  LOOP
    BEGIN
      -- Extract place_id from message
      v_place_id := (v_message.message->>'place_id')::UUID;
      
      IF v_place_id IS NOT NULL THEN
        -- Process the trait extraction
        PERFORM game_logic.update_place_traits(v_place_id);
        
        -- Archive the message (keeps history)
        PERFORM pgmq.archive('trait_extraction', v_message.msg_id);
        
        v_processed := v_processed + 1;
        
        RAISE LOG 'process_orphaned_trait_jobs: Processed place_id %, msg_id %', 
          v_place_id, v_message.msg_id;
      ELSE
        -- Invalid message, delete it
        PERFORM pgmq.delete('trait_extraction', v_message.msg_id);
        RAISE WARNING 'process_orphaned_trait_jobs: Invalid message deleted, msg_id %', 
          v_message.msg_id;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log error but continue processing other messages
      -- Message will become visible again after timeout for retry
      RAISE WARNING 'process_orphaned_trait_jobs: Failed to process msg_id %, error: %', 
        v_message.msg_id, SQLERRM;
    END;
  END LOOP;
  
  RETURN v_processed;
END;
$$;


ALTER FUNCTION "game_logic"."process_orphaned_trait_jobs" () OWNER TO "postgres";


COMMENT ON FUNCTION "game_logic"."process_orphaned_trait_jobs" () IS 'Backup processor for orphaned trait extraction jobs.

Called by pg_cron every 60 seconds to handle messages that:
1. Failed immediate processing via pg_net
2. Were enqueued but edge function was unavailable
3. Need retry after previous failure

Reads up to 5 messages per run with 60s visibility timeout.
Successfully processed messages are archived for history.
Failed messages remain in queue for retry.

Returns: Number of messages successfully processed.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/row_security_is_enabled.sql
-- --------------------------------------------------------------------------

-- Helper: row_security_is_enabled
-- Purpose: pgTAP helper to assert RLS is enabled on a table
-- Schema: public (SECURITY DEFINER)
-- Note: Simple mirror of pg_class.relrowsecurity for the given table
CREATE OR REPLACE FUNCTION "game_logic"."row_security_is_enabled" (p_schema TEXT, p_table TEXT, p_description TEXT) returns BOOLEAN language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = p_schema
      AND c.relname = p_table
      AND c.relrowsecurity
  );
END;
$$;

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/update_embedding.sql
-- --------------------------------------------------------------------------

-- Function: update_embedding
-- Category: utilities
-- Updates existing embedding with new text
CREATE OR REPLACE FUNCTION "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") returns void language "plpgsql" security definer
SET
  "search_path" = public,
  game_logic,
  extensions AS $$
DECLARE
  v_new_embedding vector(384);
BEGIN
  -- Generate new embedding
  v_new_embedding := generate_embedding(p_new_text);

  -- Update embedding record
  UPDATE embeddings
  SET
    source_text = p_new_text,
    embedding = v_new_embedding,
    updated_at = now()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Embedding with ID % not found', p_id;
  END IF;
END;
$$;


ALTER FUNCTION "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") owner TO "postgres";


comment ON function "game_logic"."update_embedding" ("p_id" UUID, "p_new_text" "text") IS 'Updates existing embedding with new text. Regenerates embedding.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/update_place_embedding.sql
-- --------------------------------------------------------------------------

-- Function: update_place_embedding
-- Category: utilities
-- Purpose: Update place embedding using weighted average (learning)
-- Uses embedding_id FK to embeddings table (not direct embedding column)
CREATE OR REPLACE FUNCTION "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION DEFAULT 0.3
) returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_embedding_id uuid;
  v_current_embedding vector(384);
  v_current_count int;
  v_weight float;
  v_blended_embedding vector(384);
BEGIN
  -- Get current embedding_id and times_encountered from places
  SELECT p.embedding_id, p.times_encountered 
  INTO v_embedding_id, v_current_count
  FROM places p
  WHERE p.id = place_id_param;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', place_id_param;
  END IF;

  -- If place has no embedding yet, create one
  IF v_embedding_id IS NULL THEN
    INSERT INTO embeddings (embedding)
    VALUES (new_embedding)
    RETURNING id INTO v_embedding_id;
    
    UPDATE places
    SET
      embedding_id = v_embedding_id,
      times_encountered = times_encountered + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  -- Get current embedding from embeddings table
  SELECT e.embedding INTO v_current_embedding
  FROM embeddings e
  WHERE e.id = v_embedding_id;

  -- Calculate weight (decreases as times_encountered increases)
  v_weight := learning_rate / (1.0 + v_current_count * 0.1);

  -- Blend embeddings using weighted average
  SELECT array_agg(
    (1.0 - v_weight) * old_val + v_weight * new_val
  )::vector(384)
  INTO v_blended_embedding
  FROM unnest(v_current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val);

  -- Update embedding in embeddings table
  UPDATE embeddings
  SET
    embedding = v_blended_embedding,
    updated_at = now()
  WHERE id = v_embedding_id;

  -- Bump times_encountered on place
  UPDATE places
  SET times_encountered = times_encountered + 1
  WHERE id = place_id_param;
END;
$$;


ALTER FUNCTION "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION
) owner TO "postgres";


comment ON function "game_logic"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "extensions"."vector",
  "learning_rate" DOUBLE PRECISION
) IS 'Updates a place''s embedding using weighted average (learning).
Weight decreases as times_encountered increases.
Uses 384-dimensional vectors (gte-small compatible per spec).
Updates embedding via embedding_id FK to embeddings table.
After update, bumps times_encountered counter.';

-- --------------------------------------------------------------------------
-- game_logic/functions/utilities/validate_user_input.sql
-- --------------------------------------------------------------------------

-- Function: validate_user_input
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text" DEFAULT 'input'
) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  trimmed_input TEXT;
BEGIN
  -- NULL check
  IF p_input IS NULL THEN
    RAISE EXCEPTION 'Invalid input: % cannot be null', p_field_name;
  END IF;

  -- Trim whitespace
  trimmed_input := trim(p_input);

  -- Empty string check (after trim)
  IF length(trimmed_input) = 0 THEN
    RAISE EXCEPTION 'Invalid input: % cannot be empty', p_field_name;
  END IF;

  -- Length validation
  IF length(p_input) > p_max_length THEN
    RAISE EXCEPTION 'Invalid input: % exceeds maximum length of % characters', p_field_name, p_max_length;
  END IF;

  -- Control character detection (reject ASCII 0-31 except tab/newline/CR)
  -- ASCII 9 = tab, 10 = newline, 13 = carriage return
  -- Note: \x00 (null byte) is already caught by this regex
  IF p_input ~ '[\x00-\x08\x0B\x0C\x0E-\x1F]' THEN
    RAISE EXCEPTION 'Invalid input: % contains forbidden control characters', p_field_name;
  END IF;

  -- Excessive newlines detection (3+ consecutive)
  IF p_input ~ '(\r?\n){3,}' THEN
    RAISE EXCEPTION 'Invalid input: % contains excessive consecutive newlines', p_field_name;
  END IF;

  RETURN trimmed_input;
END;
$$;


ALTER FUNCTION "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text"
) owner TO "postgres";


comment ON function "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text"
) IS 'Validates user input for security and data integrity.
Checks:
- NULL values
- Empty strings (after trim)
- Length limits
- Control characters (rejects ASCII 0-31 except tab/newline/CR, includes null bytes)
- Excessive consecutive newlines (3+)

Returns trimmed input if valid, raises exception otherwise.';

-- ============================================================================
-- TRIGGER DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- schema/triggers.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Database Triggers
-- ============================================================================
-- Description: Trigger definitions (CREATE TRIGGER statements)
-- Dependencies: Trigger functions must be defined first (in functions/)
-- ============================================================================
-- ============================================================================
-- game_sessions triggers
-- ============================================================================
DROP TRIGGER if EXISTS "enrich_place_on_session_complete_trigger" ON "public"."game_sessions";


CREATE TRIGGER "enrich_place_on_session_complete_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW
EXECUTE function "game_logic"."enrich_place_on_session_complete" ();


comment ON trigger "enrich_place_on_session_complete_trigger" ON "public"."game_sessions" IS 'Triggers place enrichment when a session completes successfully (was_correct = TRUE).';


DROP TRIGGER if EXISTS "on_session_approval_regenerate_traits_trigger" ON "public"."game_sessions";


CREATE TRIGGER "on_session_approval_regenerate_traits_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW WHEN (
  old.pending_review = TRUE
  AND new.pending_review = FALSE
)
EXECUTE function "game_logic"."on_session_approval_regenerate_traits" ();


comment ON trigger "on_session_approval_regenerate_traits_trigger" ON "public"."game_sessions" IS 'Triggers trait regeneration when a session is approved (pending_review: TRUE → FALSE).';

-- ============================================================================
-- VIEW DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- public/views/game_session_state.sql
-- --------------------------------------------------------------------------

-- View: game_session_state
-- Schema: public
-- Description: Exposes all game state data needed by frontend UI in a single query
-- Calculates derived status from session state (was_correct, next_turn)
-- RLS is inherited from game_sessions table - view only shows rows user can access
--
-- Status Derivation Logic:
-- - 'won': User guessed correctly (was_correct = TRUE)
-- - 'ended': Game ended and place was submitted (place_id IS NOT NULL, not won)
-- - 'needs_submission': Game ended without winning, no place submitted yet
-- - 'active': Game in progress
CREATE OR REPLACE VIEW "public"."game_session_state" AS
SELECT
  -- Session metadata
  gs.id AS session_id,
  gs.description,
  -- Derived status (calculated from state, not stored)
  CASE
    WHEN gs.was_correct = TRUE THEN 'won'::game_session_status
    WHEN gs.next_turn IS NULL
    AND gs.place_id IS NOT NULL THEN 'ended'::game_session_status
    WHEN gs.next_turn IS NULL THEN 'needs_submission'::game_session_status
    WHEN gs.next_turn ->> 'action' = 'give_up' THEN 'needs_submission'::game_session_status
    ELSE 'active'::game_session_status
  END AS status,
  -- Structured frontend JSON blobs
  CASE
    WHEN gs.next_turn ->> 'action' = 'question' THEN jsonb_build_object(
      'id',
      gs.next_turn ->> 'question_id',
      'text',
      gs.next_turn ->> 'question_text'
    )
    ELSE NULL
  END AS question,
  CASE
    WHEN gs.next_turn ->> 'action' = 'guess' THEN jsonb_build_object(
      'place_id',
      gs.next_turn ->> 'place_id',
      'place_name',
      gs.next_turn ->> 'place_name'
    )
    ELSE NULL
  END AS guess,
  CASE
    WHEN gs.place_id IS NULL THEN NULL
    ELSE jsonb_build_object(
      'id',
      gs.place_id,
      'name',
      wp.name,
      'lat',
      wp.lat,
      'lng',
      wp.lng
    )
  END AS place,
  coalesce(gs.next_turn -> 'candidates', '[]'::JSONB) AS candidates,
  -- Metadata
  (
    SELECT
      count(*)
    FROM
      game_answers
    WHERE
      session_id = gs.id
      AND (
        trait_id IS NOT NULL
        OR geographic_region_id IS NOT NULL
      )
  ) AS question_count
FROM
  game_sessions gs
  LEFT JOIN places wp ON gs.place_id = wp.id
WHERE
  gs.user_id = auth.uid ()
  OR gs.user_id IS NULL;


ALTER VIEW "public"."game_session_state" owner TO "postgres";

-- --------------------------------------------------------------------------
-- public/views/global_stats.sql
-- --------------------------------------------------------------------------

-- View: global_stats
-- Schema: public
-- Description: Provides global game statistics for analytics and leaderboards
-- Only accessible to service_role for privacy
CREATE OR REPLACE VIEW "public"."global_stats" AS
SELECT
  -- Global session counts
  count(*) AS total_sessions,
  count(
    CASE
      WHEN was_correct = TRUE THEN 1
    END
  ) AS sessions_won,
  count(
    CASE
      WHEN was_correct = FALSE THEN 1
    END
  ) AS sessions_lost,
  count(
    CASE
      WHEN was_correct IS NULL
      AND next_turn IS NULL THEN 1
    END
  ) AS sessions_submitted,
  count(
    CASE
      WHEN next_turn IS NOT NULL THEN 1
    END
  ) AS active_sessions,
  -- Global win rate
  CASE
    WHEN count(
      CASE
        WHEN was_correct IS NOT NULL THEN 1
      END
    ) = 0 THEN 0
    ELSE round(
      (
        count(
          CASE
            WHEN was_correct = TRUE THEN 1
          END
        )::NUMERIC / count(
          CASE
            WHEN was_correct IS NOT NULL THEN 1
          END
        )
      ) * 100,
      2
    )
  END AS global_win_rate_percent,
  -- Unique users
  count(DISTINCT user_id) AS unique_users,
  count(
    DISTINCT CASE
      WHEN user_id IS NULL THEN 'anonymous'::TEXT
      ELSE user_id::TEXT
    END
  ) AS total_players,
  -- Average questions per completed session
  round(
    avg(
      CASE
        WHEN (
          was_correct IS NOT NULL
          OR (
            was_correct IS NULL
            AND next_turn IS NULL
          )
        ) THEN (
          SELECT
            count(*)
          FROM
            game_answers ga
          WHERE
            ga.session_id = gs.id
        )
        ELSE NULL
      END
    ),
    2
  ) AS avg_questions_per_session,
  -- Most popular places (most guessed)
  (
    SELECT
      jsonb_agg(
        jsonb_build_object(
          'place_id',
          t.place_id,
          'place_name',
          t.place_name,
          'times_guessed',
          t.times_guessed
        )
        ORDER BY
          t.times_guessed DESC
      )
    FROM
      (
        SELECT
          gs2.place_id,
          p.name AS place_name,
          count(*) AS times_guessed
        FROM
          game_sessions gs2
          JOIN places p ON gs2.place_id = p.id
        WHERE
          gs2.place_id IS NOT NULL
        GROUP BY
          gs2.place_id,
          p.name
        ORDER BY
          count(*) DESC
        LIMIT
          10
      ) t
  ) AS top_places_guessed,
  -- Recent activity (last 24 hours)
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '24 hours' THEN 1
    END
  ) AS sessions_last_24h,
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '7 days' THEN 1
    END
  ) AS sessions_last_7d,
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '30 days' THEN 1
    END
  ) AS sessions_last_30d,
  -- Database stats
  (
    SELECT
      count(*)
    FROM
      places
  ) AS total_places,
  (
    SELECT
      count(*)
    FROM
      place_traits
  ) AS total_traits,
  (
    SELECT
      count(*)
    FROM
      embeddings
  ) AS total_embeddings
FROM
  game_sessions gs;


ALTER VIEW "public"."global_stats" owner TO "postgres";


-- Permissions
REVOKE ALL ON TABLE public.global_stats
FROM
  public;


REVOKE ALL ON TABLE public.global_stats
FROM
  anon;


GRANT
SELECT
  ON TABLE public.global_stats TO authenticated;


GRANT
SELECT
  ON TABLE public.global_stats TO service_role;

-- --------------------------------------------------------------------------
-- public/views/places_with_geometry.sql
-- --------------------------------------------------------------------------

-- View: places_with_geometry
-- Schema: public
-- Description: Places with geometry as GeoJSON for map rendering
-- Note: Large geometries (>500 points) are simplified for performance
CREATE OR REPLACE VIEW "public"."places_with_geometry" AS
SELECT
  p.id,
  p.name,
  p.lat,
  p.lng,
  p.times_encountered,
  -- Simplify large geometries (cities) while keeping small ones (buildings) intact
  CASE
    WHEN extensions.st_npoints (p.geom) > 500 THEN extensions.st_asgeojson (extensions.st_simplify (p.geom, 0.001))::JSONB
    ELSE extensions.st_asgeojson (p.geom)::JSONB
  END AS geometry
FROM
  places p
WHERE
  p.lat IS NOT NULL
  AND p.lng IS NOT NULL
  AND p.pending_review = FALSE;


ALTER VIEW "public"."places_with_geometry" owner TO "postgres";


-- Permissions: public read access
GRANT
SELECT
  ON TABLE public.places_with_geometry TO anon;


GRANT
SELECT
  ON TABLE public.places_with_geometry TO authenticated;


GRANT
SELECT
  ON TABLE public.places_with_geometry TO service_role;

-- --------------------------------------------------------------------------
-- public/views/user_stats.sql
-- --------------------------------------------------------------------------

-- View: user_stats
-- Schema: public
-- Description: Provides user-specific game statistics per spec
-- Spec columns: games_played, games_won, win_rate, avg_turns_to_win, places_added, last_played_at
-- RLS is inherited from game_sessions table - view only shows rows user can access
CREATE OR REPLACE VIEW "public"."user_stats" AS
SELECT
  -- games_played: Total completed games (won or lost, not active)
  count(
    CASE
      WHEN was_correct IS NOT NULL THEN 1
    END
  ) AS games_played,
  -- games_won: Games where user guessed correctly
  count(
    CASE
      WHEN was_correct = TRUE THEN 1
    END
  ) AS games_won,
  -- win_rate: Percentage of games won (0-100)
  CASE
    WHEN count(
      CASE
        WHEN was_correct IS NOT NULL THEN 1
      END
    ) = 0 THEN 0::NUMERIC
    ELSE round(
      (
        count(
          CASE
            WHEN was_correct = TRUE THEN 1
          END
        )::NUMERIC / count(
          CASE
            WHEN was_correct IS NOT NULL THEN 1
          END
        )
      ) * 100,
      2
    )
  END AS win_rate,
  -- avg_turns_to_win: Average number of turns in winning games
  round(
    avg(
      CASE
        WHEN was_correct = TRUE THEN (
          SELECT
            count(*)
          FROM
            game_answers ga
          WHERE
            ga.session_id = gs.id
        )
        ELSE NULL
      END
    ),
    2
  ) AS avg_turns_to_win,
  -- places_added: Count of places submitted by this user
  (
    SELECT
      count(DISTINCT place_id)
    FROM
      game_sessions
    WHERE
      user_id = auth.uid ()
      AND place_id IS NOT NULL
      AND was_correct = FALSE
  ) AS places_added,
  -- last_played_at: Most recent game session
  max(created_at) AS last_played_at
FROM
  game_sessions gs
WHERE
  gs.user_id = auth.uid ()
  OR gs.user_id IS NULL
GROUP BY
  gs.user_id;


ALTER VIEW "public"."user_stats" owner TO "postgres";


-- Permissions
REVOKE ALL ON TABLE public.user_stats
FROM
  public;


REVOKE ALL ON TABLE public.user_stats
FROM
  anon;


GRANT
SELECT
  ON TABLE public.user_stats TO authenticated;


GRANT
SELECT
  ON TABLE public.user_stats TO service_role;

