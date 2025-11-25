-- Migration: Initial Schema and Functions
-- Generated: 2025-11-21T11:05:43.321Z
-- Mode: DEV (clean rebuild)
-- Schema files: 5
-- Function files: 37
-- Trigger files: 1

-- ============================================================================
-- SCHEMA DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- Schema: 01_extensions.sql
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

-- --------------------------------------------------------------------------
-- Schema: 02_tables.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Core Database Tables
-- ============================================================================
-- Description: All table definitions including columns, constraints, and defaults
-- Dependencies: Extensions (01_extensions.sql)
-- ============================================================================
-- ============================================================================
-- geographic_regions table
-- ============================================================================
-- Stores geographic regions (continents and countries) from Natural Earth
-- Used to generate geographic questions dynamically
CREATE TABLE IF NOT EXISTS "public"."geographic_regions" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "name" "text" NOT NULL,
  "level" "text" NOT NULL CHECK ("level" IN ('continent', 'country')),
  "geom" "public"."geometry" (multipolygon, 4326) NOT NULL,
  "continent_id" "uuid",
  "iso_code" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."geographic_regions" owner TO "postgres";


ALTER TABLE ONLY "public"."geographic_regions"
ADD CONSTRAINT "geographic_regions_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."geographic_regions"
ADD CONSTRAINT "geographic_regions_continent_id_fkey" FOREIGN key ("continent_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


comment ON TABLE "public"."geographic_regions" IS 'Geographic regions (continents and countries) from Natural Earth.
Used to generate geographic questions dynamically via v_geographic_questions view.
- level: continent or country
- continent_id: NULL for continents, references continent for countries
- iso_code: ISO 3166-1 alpha-2 code for countries (e.g., FR, JP)';


-- ============================================================================
-- embeddings table
-- ============================================================================
-- Stores text embeddings separately from entities for efficient querying
CREATE TABLE IF NOT EXISTS "public"."embeddings" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "text" "text" NOT NULL,
  "text_hash" "text" NOT NULL,
  "embedding" "public"."vector" (1024) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."embeddings" owner TO "postgres";


ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_text_hash_key" UNIQUE ("text_hash");


comment ON TABLE "public"."embeddings" IS 'Stores text embeddings separately from entities. Text is hashed for deduplication and fast lookup.';


-- ============================================================================
-- places table
-- ============================================================================
-- Stores geographic locations with trait-based descriptions
CREATE TABLE IF NOT EXISTS "public"."places" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "name" "text" NOT NULL,
  "osm_id" "text" NOT NULL,
  "lat" DOUBLE PRECISION,
  "lng" DOUBLE PRECISION,
  "geom" "public"."geometry" (polygon, 4326),
  "traits" TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
  "embedding_id" "uuid",
  "times_encountered" INTEGER DEFAULT 0 NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."places" owner TO "postgres";


ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_osm_id_key" UNIQUE ("osm_id");


ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."places"
ADD CONSTRAINT "places_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- ============================================================================
-- place_traits table
-- ============================================================================
-- Stores canonical trait definitions used to describe and filter places
CREATE TABLE IF NOT EXISTS "public"."place_traits" (
  "id" TEXT NOT NULL,
  "clause" TEXT NOT NULL,
  "category" TEXT NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."place_traits" owner TO "postgres";


ALTER TABLE ONLY "public"."place_traits"
ADD CONSTRAINT "place_traits_pkey" PRIMARY KEY ("id");


comment ON TABLE "public"."place_traits" IS 'Canonical trait vocabulary. Each trait provides a short descriptive clause that can be embedded or composed into constraints.';


-- ============================================================================
-- place_trait_links table
-- ============================================================================
-- Links places to traits while tracking provenance for enrichment sources
CREATE TABLE IF NOT EXISTS "public"."place_trait_links" (
  "place_id" UUID NOT NULL,
  "trait_id" TEXT NOT NULL,
  "source_type" TEXT NOT NULL DEFAULT 'nominatim'::TEXT,
  "source_metadata" JSONB DEFAULT '{}'::JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  CONSTRAINT "place_trait_links_source_type_check" CHECK (char_length(btrim("source_type")) > 0)
);


ALTER TABLE "public"."place_trait_links" owner TO "postgres";


ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_pkey" PRIMARY KEY ("place_id", "trait_id");


ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."place_traits" ("id") ON DELETE CASCADE;


comment ON TABLE "public"."place_trait_links" IS 'Associates places with traits plus provenance details describing how/why the trait was assigned.';


-- ============================================================================
-- question_stats table
-- ============================================================================
-- Tracks effectiveness of questions (generated on-the-fly from traits/regions)
CREATE TABLE IF NOT EXISTS "public"."question_stats" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "question_type" "public"."question_type" NOT NULL,
  "trait_id" TEXT,
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


ALTER TABLE "public"."question_stats" owner TO "postgres";


ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."place_traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


comment ON TABLE "public"."question_stats" IS 'Tracks effectiveness of questions. Questions are generated on-the-fly from traits/regions, not stored as text.';


comment ON COLUMN "public"."question_stats"."trait_id" IS 'Reference to place_traits for semantic questions (e.g., "Does it have <trait.clause>?")';


comment ON COLUMN "public"."question_stats"."geographic_region_id" IS 'Reference to geographic_regions for geographic questions (e.g., "Is it in <region.name>?")';


-- ============================================================================
-- game_answers table
-- ============================================================================
-- Records each answer (question response or wrong guess) during a game session
CREATE TABLE IF NOT EXISTS "public"."game_answers" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "session_id" "uuid" NOT NULL,
  "trait_id" TEXT,
  "geographic_region_id" "uuid",
  "answer" BOOLEAN NOT NULL,
  "place_id" "uuid",
  "candidates" "jsonb",
  "question_text" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."game_answers" owner TO "postgres";


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."place_traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


comment ON TABLE "public"."game_answers" IS 'Records player answers. Questions are generated from trait_id or geographic_region_id, not stored.';


-- ============================================================================
-- game_sessions table
-- ============================================================================
-- Tracks active and completed game sessions with trait-based state
CREATE TABLE IF NOT EXISTS "public"."game_sessions" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid",
  "place_id" "uuid",
  "was_correct" BOOLEAN,
  "description" "text" NOT NULL CHECK (
    length(trim("description")) > 0
    AND length("description") <= 500
  ),
  "description_language_code" "text" DEFAULT 'en'::"text" NOT NULL,
  "affirmed_trait_ids" TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
  "denied_trait_ids" TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
  "description_embedding_id" UUID,
  "affirmed_trait_embedding_id" UUID,
  "denied_trait_embedding_id" UUID,
  "pending_review" BOOLEAN DEFAULT FALSE NOT NULL,
  "submitted_place_name" "text",
  "submitted_lat" DOUBLE PRECISION,
  "submitted_lng" DOUBLE PRECISION,
  "submitted_nominatim_id" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "next_turn" "jsonb"
);


ALTER TABLE "public"."game_sessions" owner TO "postgres";


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id");


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_description_embedding_id_fkey" FOREIGN key ("description_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_affirmed_trait_embedding_id_fkey" FOREIGN key ("affirmed_trait_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_denied_trait_embedding_id_fkey" FOREIGN key ("denied_trait_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_session_id_fkey" FOREIGN key ("session_id") REFERENCES "public"."game_sessions" ("id") ON DELETE CASCADE;


comment ON COLUMN "public"."game_sessions"."next_turn" IS 'Cached next turn for the game session. Stores one of:
- {"action": "question", "question_id": "uuid", "question_text": "...", "candidates": [...]}
- {"action": "guess", "place_id": "uuid", "place_name": "...", "candidates": [...]}
- {"action": "give_up", "reason": "no_candidates"}
- NULL (session won/lost - check was_correct)

Generated by decide_next_turn() and cached for performance.
Cleared by play_turn() when user answers/confirms, then recalculated for next turn.';


-- ============================================================================
-- app_settings table
-- ============================================================================
-- Stores application configuration including LLM prompts
CREATE TABLE IF NOT EXISTS "public"."app_settings" (
  "key" "text" NOT NULL,
  "value" "text" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "public"."app_settings" owner TO "postgres";


comment ON TABLE "public"."app_settings" IS 'Application configuration settings including LLM system prompts';


comment ON COLUMN "public"."app_settings"."key" IS 'Configuration key (e.g., question_generation_system_prompt)';


comment ON COLUMN "public"."app_settings"."value" IS 'Configuration value (e.g., system prompt text)';


comment ON COLUMN "public"."app_settings"."description" IS 'Human-readable description of the setting';


-- ============================================================================

-- --------------------------------------------------------------------------
-- Schema: 03_rls.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Row Level Security (RLS) Policies
-- ============================================================================
-- Description: RLS policies for all tables to enforce data access control
-- Dependencies: Tables (02_tables.sql)
-- ============================================================================
-- ============================================================================
-- places table RLS
-- ============================================================================
ALTER TABLE "public"."places" enable ROW level security;


DROP POLICY if EXISTS "Places are viewable by everyone" ON "public"."places";


DROP POLICY if EXISTS "Service role can insert places" ON "public"."places";


DROP POLICY if EXISTS "Service role can update places" ON "public"."places";


DROP POLICY if EXISTS "Users can delete their own places" ON "public"."places";


CREATE POLICY "Places are viewable by everyone" ON "public"."places" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can insert places" ON "public"."places" FOR insert
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


CREATE POLICY "Service role can update places" ON "public"."places"
FOR UPDATE
  USING (("auth"."role" () = 'service_role'::"text"));


CREATE POLICY "Users can delete their own places" ON "public"."places" FOR delete USING (
  (
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
  )
);


-- ============================================================================
-- place_traits table RLS
-- ============================================================================
ALTER TABLE "public"."place_traits" enable ROW level security;


DROP POLICY if EXISTS "Place traits viewable by everyone" ON "public"."place_traits";


DROP POLICY if EXISTS "Service role can manage place traits" ON "public"."place_traits";


CREATE POLICY "Place traits viewable by everyone" ON "public"."place_traits" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place traits" ON "public"."place_traits" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- place_trait_links table RLS
-- ============================================================================
ALTER TABLE "public"."place_trait_links" enable ROW level security;


DROP POLICY if EXISTS "Place trait links viewable by everyone" ON "public"."place_trait_links";


DROP POLICY if EXISTS "Service role can manage place trait links" ON "public"."place_trait_links";


CREATE POLICY "Place trait links viewable by everyone" ON "public"."place_trait_links" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place trait links" ON "public"."place_trait_links" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- question_stats table RLS
-- ============================================================================
ALTER TABLE "public"."question_stats" enable ROW level security;


DROP POLICY if EXISTS "Question stats viewable by everyone" ON "public"."question_stats";


DROP POLICY if EXISTS "Service role can manage question stats" ON "public"."question_stats";


CREATE POLICY "Question stats viewable by everyone" ON "public"."question_stats" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage question stats" ON "public"."question_stats" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- game_answers table RLS
-- ============================================================================
ALTER TABLE "public"."game_answers" enable ROW level security;


DROP POLICY if EXISTS "Users can insert answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can update answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can view answers for their sessions" ON "public"."game_answers";


CREATE POLICY "Users can insert answers for their sessions" ON "public"."game_answers" FOR insert
WITH
  CHECK (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


CREATE POLICY "Users can update answers for their sessions" ON "public"."game_answers"
FOR UPDATE
  USING (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


CREATE POLICY "Users can view answers for their sessions" ON "public"."game_answers" FOR
SELECT
  USING (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


-- ============================================================================
-- game_sessions table RLS
-- ============================================================================
ALTER TABLE "public"."game_sessions" enable ROW level security;


DROP POLICY if EXISTS "Users can view their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can insert their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can update their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can delete their own game sessions" ON "public"."game_sessions";


CREATE POLICY "Users can view their own game sessions" ON "public"."game_sessions" FOR
SELECT
  USING (
    (
      ("auth"."uid" () = "user_id")
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can insert their own game sessions" ON "public"."game_sessions" FOR insert
WITH
  CHECK (
    (
      (
        ("auth"."uid" () IS NOT NULL)
        AND ("auth"."uid" () = "user_id")
      )
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can update their own game sessions" ON "public"."game_sessions"
FOR UPDATE
  USING (
    (
      ("auth"."uid" () = "user_id")
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can delete their own game sessions" ON "public"."game_sessions" FOR delete USING (
  (
    ("auth"."uid" () = "user_id")
    OR (
      ("auth"."uid" () IS NULL)
      AND ("user_id" IS NULL)
    )
    OR ("auth"."role" () = 'service_role'::"text")
  )
);


-- ============================================================================
-- app_settings table RLS
-- ============================================================================
ALTER TABLE "public"."app_settings" enable ROW level security;


DROP POLICY if EXISTS "App settings are readable by everyone" ON "public"."app_settings";


DROP POLICY if EXISTS "Service role can manage app settings" ON "public"."app_settings";


CREATE POLICY "App settings are readable by everyone" ON "public"."app_settings" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage app settings" ON "public"."app_settings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));

-- --------------------------------------------------------------------------
-- Schema: 04_indexes.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Database Indexes
-- ============================================================================
-- Description: All indexes for performance optimization of queries
-- Dependencies: Tables (02_tables.sql)
-- ============================================================================
-- ============================================================================
-- geographic_regions table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "idx_geographic_regions_level" ON "public"."geographic_regions" USING "btree" ("level");


CREATE INDEX if NOT EXISTS "idx_geographic_regions_continent" ON "public"."geographic_regions" USING "btree" ("continent_id");


CREATE INDEX if NOT EXISTS "idx_geographic_regions_geom" ON "public"."geographic_regions" USING "gist" ("geom");


CREATE INDEX if NOT EXISTS "idx_geographic_regions_iso_code" ON "public"."geographic_regions" USING "btree" ("iso_code");


-- ============================================================================
-- embeddings table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "idx_embeddings_hash" ON "public"."embeddings" USING "btree" ("text_hash");


CREATE INDEX if NOT EXISTS "idx_embeddings_hnsw" ON "public"."embeddings" USING "hnsw" ("embedding" "public"."vector_cosine_ops")
WITH
  ("m" = '16', "ef_construction" = '64');


-- ============================================================================
-- places table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "idx_places_geom_gist" ON "public"."places" USING "gist" ("geom");


CREATE INDEX if NOT EXISTS "idx_places_times_encountered" ON "public"."places" USING "btree" ("times_encountered" DESC);


CREATE INDEX if NOT EXISTS "idx_places_traits_gin" ON "public"."places" USING "gin" ("traits");


CREATE INDEX if NOT EXISTS "idx_places_embedding_id" ON "public"."places" USING "btree" ("embedding_id");


CREATE INDEX if NOT EXISTS "places_geom_idx" ON "public"."places" USING "gist" ("geom");


CREATE UNIQUE INDEX if NOT EXISTS "places_osm_idx" ON "public"."places" USING "btree" ("osm_id");


-- =========================================================================
-- place_traits table indexes
-- =========================================================================
CREATE INDEX if NOT EXISTS "idx_place_traits_category" ON "public"."place_traits" USING "btree" ("category");


-- =========================================================================
-- place_trait_links table indexes
-- =========================================================================
CREATE INDEX if NOT EXISTS "idx_place_trait_links_trait" ON "public"."place_trait_links" USING "btree" ("trait_id");


CREATE INDEX if NOT EXISTS "idx_place_trait_links_source" ON "public"."place_trait_links" USING "btree" ("source_type");


-- =========================================================================
-- question_stats table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "idx_question_stats_effectiveness" ON "public"."question_stats" USING "btree" ("effectiveness_score" DESC, "times_asked" DESC);


CREATE INDEX if NOT EXISTS "idx_question_stats_type" ON "public"."question_stats" USING "btree" ("question_type");


CREATE INDEX if NOT EXISTS "idx_question_stats_trait" ON "public"."question_stats" USING "btree" ("trait_id");


CREATE INDEX if NOT EXISTS "idx_question_stats_region" ON "public"."question_stats" USING "btree" ("geographic_region_id");


-- ============================================================================
-- game_answers table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "game_answers_session_idx" ON "public"."game_answers" USING "btree" ("session_id");


CREATE INDEX if NOT EXISTS "idx_game_answers_session_created" ON "public"."game_answers" USING "btree" ("session_id", "created_at");


CREATE INDEX if NOT EXISTS "idx_game_answers_trait" ON "public"."game_answers" USING "btree" ("trait_id");


CREATE INDEX if NOT EXISTS "idx_game_answers_region" ON "public"."game_answers" USING "btree" ("geographic_region_id");


-- ============================================================================
-- game_sessions table indexes
-- ============================================================================
CREATE INDEX if NOT EXISTS "game_sessions_pending_idx" ON "public"."game_sessions" USING "btree" ("pending_review", "created_at");


CREATE INDEX if NOT EXISTS "idx_game_sessions_user_created" ON "public"."game_sessions" USING "btree" ("user_id", "created_at" DESC);


CREATE INDEX if NOT EXISTS "idx_game_sessions_place_created" ON "public"."game_sessions" USING "btree" ("place_id", "created_at" DESC);

-- --------------------------------------------------------------------------
-- Schema: 06_views.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Database Views
-- ============================================================================
-- Description: Views that expose game state data to frontend
-- Dependencies: Tables (02_tables.sql)
-- ============================================================================
-- ============================================================================
-- game_session_state view
-- ============================================================================
-- Exposes all game state data needed by frontend UI in a single query
-- Calculates derived status from session state (was_correct, next_turn)
-- RLS is inherited from game_sessions table - view only shows rows user can access
--
-- Status Derivation Logic:
-- - 'won': User guessed correctly (was_correct = TRUE)
-- - 'ended': Hit 5-turn limit without winning (was_correct = FALSE)
-- - 'needs_submission': Zero candidates, needs manual place submission (next_turn = NULL, was_correct = NULL)
-- - 'active': Game in progress (next_turn != NULL)
CREATE OR REPLACE VIEW "public"."game_session_state" AS
SELECT
  -- Session metadata
  gs.id AS session_id,
  gs.description,
  -- Derived status (calculated from state, not stored)
  CASE
    WHEN gs.was_correct = TRUE THEN 'won'::game_session_status
    WHEN gs.next_turn IS NULL
    AND gs.was_correct = FALSE THEN 'ended'::game_session_status
    WHEN gs.next_turn IS NULL THEN 'needs_submission'::game_session_status
    ELSE 'active'::game_session_status
  END AS status,
  -- Next turn action (cached)
  gs.next_turn,
  -- Flattened next_turn fields for frontend access
  gs.next_turn ->> 'question_text' AS current_question_text,
  gs.next_turn ->> 'question_id' AS current_question_id,
  gs.next_turn ->> 'place_name' AS pending_guess_place_name,
  gs.next_turn ->> 'place_id' AS pending_guess_place_id,
  -- Win state (if won)
  gs.place_id AS correct_place_id,
  wp.name AS correct_place_name,
  wp.lat AS correct_place_lat,
  wp.lng AS correct_place_lng,
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

-- ============================================================================
-- FUNCTION DEFINITIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- Function: game/apply_answer_to_session_state.sql
-- --------------------------------------------------------------------------

-- Function: apply_answer_to_session_state
-- Category: game
-- Applies a player's answer to the session state by updating affirmed/denied traits
-- and regenerating trait embeddings used by get_candidates
CREATE OR REPLACE FUNCTION "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) returns void language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_session_record RECORD;
  v_affirmed_ids TEXT[] := ARRAY[]::TEXT[];
  v_denied_ids TEXT[] := ARRAY[]::TEXT[];
  v_description TEXT := '';
  v_affirmed_text TEXT;
  v_denied_text TEXT;
  v_manual_suffix TEXT;
  v_new_constraint TEXT;
  v_new_trait_embedding vector(1024);
BEGIN
  -- Get current session state
  SELECT * INTO v_session_record
  FROM game_sessions gs
  WHERE gs.id = p_session_id;
  
  IF v_session_record.id IS NULL THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;
  
  v_affirmed_ids := COALESCE(v_session_record.affirmed_trait_ids, ARRAY[]::TEXT[]);
  v_denied_ids := COALESCE(v_session_record.denied_trait_ids, ARRAY[]::TEXT[]);
  v_description := COALESCE(v_session_record.description, '');

  -- Update canonical trait arrays when question provides a trait_id
  IF p_trait_id IS NOT NULL THEN
    IF p_answer THEN
      v_affirmed_ids := array_append(array_remove(v_affirmed_ids, p_trait_id), p_trait_id);
      v_denied_ids := array_remove(v_denied_ids, p_trait_id);
    ELSE
      v_denied_ids := array_append(array_remove(v_denied_ids, p_trait_id), p_trait_id);
      v_affirmed_ids := array_remove(v_affirmed_ids, p_trait_id);
    END IF;
  END IF;

  -- Build affirmed/denied clause strings from canonical traits
  SELECT string_agg(pt.clause, '; ' ORDER BY pt.clause)
  INTO v_affirmed_text
  FROM place_traits pt
  WHERE pt.id = ANY(v_affirmed_ids);

  SELECT string_agg(pt.clause, '; ' ORDER BY pt.clause)
  INTO v_denied_text
  FROM place_traits pt
  WHERE pt.id = ANY(v_denied_ids);

  -- Regenerate trait embeddings if anything changed
  IF v_affirmed_ids IS DISTINCT FROM v_session_record.affirmed_trait_ids
     OR v_denied_ids IS DISTINCT FROM v_session_record.denied_trait_ids THEN

    UPDATE game_sessions
    SET
      affirmed_trait_ids = v_affirmed_ids,
      denied_trait_ids = v_denied_ids,
      affirmed_trait_embedding_id = CASE 
        WHEN v_affirmed_text IS NOT NULL THEN get_or_create_embedding(v_affirmed_text)
        ELSE NULL
      END,
      denied_trait_embedding_id = CASE 
        WHEN v_denied_text IS NOT NULL THEN get_or_create_embedding(v_denied_text)
        ELSE NULL
      END
    WHERE id = p_session_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) owner TO "postgres";


comment ON function "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) IS 'Applies a user answer to the session.

Behavior:
- Uses trait_id to update affirmed/denied trait arrays (used for filtering)
- Builds trait constraint from affirmed traits
- Regenerates trait_embedding from affirmed traits (used by get_candidates)
- Geographic questions are handled separately (only affect bounding boxes)

Parameters:
- p_session_id: Session ID
- p_answer: User answer (true/false)
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
';

-- --------------------------------------------------------------------------
-- Function: game/decide_next_turn.sql
-- --------------------------------------------------------------------------

-- Function: decide_next_turn
-- Category: game
-- Purpose: Decide whether to guess or ask a question based on current candidates
-- Builds complete next_turn JSONB with action and candidates
-- Updated to accept cached candidates to avoid redundant get_candidates calls
CREATE OR REPLACE FUNCTION "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) returns TABLE (session_id UUID) language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_candidates JSONB;
  v_candidate_count INT;
  v_top_confidence FLOAT;
  v_confidence_gap FLOAT;
  v_top_candidate JSONB;
  v_question_record RECORD;
  v_next_turn JSONB;
  v_total_turns INT;
  v_max_turns INT;
  v_guess_confidence_threshold FLOAT;
  v_guess_confidence_gap_threshold FLOAT;
  v_guess_high_confidence_threshold FLOAT;
BEGIN
  -- Get configuration from app_settings (FAIL if missing)
  v_max_turns := get_max_turns();
  
  SELECT value::FLOAT INTO STRICT v_guess_confidence_threshold 
  FROM app_settings WHERE key = 'guess_confidence_threshold';
  
  SELECT value::FLOAT INTO STRICT v_guess_confidence_gap_threshold
  FROM app_settings WHERE key = 'guess_confidence_gap_threshold';
  
  SELECT value::FLOAT INTO STRICT v_guess_high_confidence_threshold
  FROM app_settings WHERE key = 'guess_high_confidence_threshold';

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
    
    RETURN QUERY SELECT p_session_id;
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
    
    RETURN QUERY SELECT p_session_id;
    RETURN;
  END IF;

  -- Get top candidate's confidence and gap
  SELECT 
    COALESCE((elem->>'confidence')::float, 0.0),
    COALESCE((elem->>'confidence_gap')::float, 0.0),
    elem
  INTO v_top_confidence, v_confidence_gap, v_top_candidate
  FROM jsonb_array_elements(v_candidates) elem
  ORDER BY (elem->>'confidence')::float DESC
  LIMIT 1;

  -- Apply guess policy
  -- Guess if: at max_turns, only 1 candidate, super confident (>=1.0), or good confidence+gap
  IF v_total_turns >= v_max_turns
     OR v_candidate_count = 1
     OR v_top_confidence >= v_guess_high_confidence_threshold
     OR (v_top_confidence >= v_guess_confidence_threshold 
         AND v_confidence_gap >= v_guess_confidence_gap_threshold)
  THEN
    -- Build GUESS next_turn using pure formatter (SRP)
    v_next_turn := build_guess_turn(v_top_candidate, v_candidates);
  ELSE
    -- Ask a question: call get_question with candidates
    SELECT * INTO v_question_record
    FROM get_question(p_session_id, v_candidates)
    LIMIT 1;
    
    IF v_question_record.question_type IS NULL THEN
      RAISE EXCEPTION 'Failed to choose next question for session %', p_session_id;
    END IF;
    
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

  -- Store next_turn
  UPDATE game_sessions
  SET next_turn = v_next_turn
  WHERE id = p_session_id;

  -- Return session_id
  RETURN QUERY SELECT p_session_id;
END;
$$;


ALTER FUNCTION "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."decide_next_turn" ("p_session_id" "uuid", "p_candidates" JSONB) IS 'Orchestrates next turn decision: guess or question.

Parameters:
- p_session_id: Session ID
- p_candidates: Candidates JSONB array (caller must provide)

Responsibilities (SRP - Orchestration only):
1. Get/validate candidates
2. Apply guess policy (confidence + gap thresholds)
3. Call get_question() if asking question (delegates to question domain)
4. Call build_guess_turn() or build_question_turn() for formatting (pure functions)
5. Update database with next_turn

Returns next_turn JSONB structure:
- {"action": "guess", "place_id": "...", "place_name": "...", "candidates": [...]}
- {"action": "question", "question_id": "...", "question_text": "...", "candidates": [...]}
- NULL (if no candidates available)

Called by:
- start_game() after creating new session (fetches candidates first)
- handle_question() after user answers question (passes candidates)
- handle_guess() after wrong guess (passes candidates)

Configuration (from app_settings):
- max_turns, guess_confidence_threshold, guess_confidence_gap_threshold

Returns: session_id';

-- --------------------------------------------------------------------------
-- Function: game/filter_geographic_candidates.sql
-- --------------------------------------------------------------------------

-- Function: filter_geographic_candidates
-- Category: game
-- Purpose: Apply geographic filters and calculate distance metrics
-- Returns: Places that pass geographic criteria + distance from region center
CREATE OR REPLACE FUNCTION "public"."filter_geographic_candidates" ("p_session_id" UUID) returns TABLE (
  id UUID,
  name TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  geom geometry,
  traits TEXT[],
  embedding_id UUID,
  distance_from_bbox_center DOUBLE PRECISION
) language "plpgsql" AS $$
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
    AND ga.answer = TRUE
    AND ga.geographic_region_id IS NOT NULL;

  SELECT ARRAY_AGG(gr.geom)
  INTO v_exclude_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = FALSE
    AND ga.geographic_region_id IS NOT NULL;

  -- Apply geographic filters and calculate distance metrics
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    p.geom,
    p.traits,
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
  WHERE p.embedding_id IS NOT NULL
    AND p.geom IS NOT NULL
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


ALTER FUNCTION "public"."filter_geographic_candidates" ("p_session_id" UUID) owner TO "postgres";


comment ON function "public"."filter_geographic_candidates" ("p_session_id" UUID) IS 'Filters places by geographic criteria using actual geometries and calculates distance metrics.

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
-- Function: game/filter_semantic_candidates.sql
-- --------------------------------------------------------------------------

-- Function: filter_semantic_candidates
-- Category: game
-- Purpose: Calculate semantic similarity scores for specific place IDs
-- Returns: Place IDs with similarity scores
CREATE OR REPLACE FUNCTION "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) returns TABLE (
  place_id UUID,
  base_description_similarity DOUBLE PRECISION,
  affirmed_trait_similarity DOUBLE PRECISION,
  denied_trait_similarity DOUBLE PRECISION
) language "plpgsql" AS $$
DECLARE
  v_description_embedding vector(1024);
  v_affirmed_embedding vector(1024);
  v_denied_embedding vector(1024);
  v_semantic_threshold FLOAT;
BEGIN
  -- Get semantic similarity threshold from settings
  SELECT value::FLOAT INTO v_semantic_threshold
  FROM app_settings 
  WHERE key = 'semantic_similarity_threshold';
  
  IF v_semantic_threshold IS NULL THEN
    RAISE EXCEPTION 'Missing required app_setting: semantic_similarity_threshold';
  END IF;

  -- Get session embeddings
  SELECT
    de_desc.embedding as description_embedding,
    de_affirmed.embedding as affirmed_embedding,
    de_denied.embedding as denied_embedding
  INTO
    v_description_embedding,
    v_affirmed_embedding,
    v_denied_embedding
  FROM game_sessions gs
  LEFT JOIN embeddings de_desc ON de_desc.id = gs.description_embedding_id
  LEFT JOIN embeddings de_affirmed ON de_affirmed.id = gs.affirmed_trait_embedding_id
  LEFT JOIN embeddings de_denied ON de_denied.id = gs.denied_trait_embedding_id
  WHERE gs.id = p_session_id;

  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', p_session_id;
  END IF;

  -- Calculate semantic similarity scores for given place IDs
  RETURN QUERY
  SELECT
    p.id AS place_id,
    (1 - (e.embedding <=> v_description_embedding))::DOUBLE PRECISION AS base_description_similarity,
    CASE
      WHEN v_affirmed_embedding IS NOT NULL
      THEN (1 - (e.embedding <=> v_affirmed_embedding))::DOUBLE PRECISION
      ELSE NULL
    END AS affirmed_trait_similarity,
    CASE
      WHEN v_denied_embedding IS NOT NULL
      THEN (1 - (e.embedding <=> v_denied_embedding))::DOUBLE PRECISION
      ELSE NULL
    END AS denied_trait_similarity
  FROM
    places p
    JOIN embeddings e ON e.id = p.embedding_id
  WHERE
    p.id = ANY (p_place_ids)
    -- Only return candidates above base similarity threshold
    AND (1 - (e.embedding <=> v_description_embedding)) > v_semantic_threshold;
END;
$$;


ALTER FUNCTION "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) owner TO "postgres";


comment ON function "public"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) IS 'Calculates semantic similarity scores for specific place IDs (SRP: Semantics only).

Input:
- p_session_id: Session to get embeddings from
- p_place_ids: Array of place IDs to score (from geographic filter)

Calculates:
- base_description_similarity: Cosine similarity with session description
- affirmed_trait_similarity: Cosine similarity with affirmed traits (if any)
- denied_trait_similarity: Cosine similarity with denied traits (if any)

Threshold: Only returns places with base_description_similarity > 0.5

Returns: Only similarity scores (no geographic data, no composite scoring).

Called by: get_candidates() which joins with geographic results.';

-- --------------------------------------------------------------------------
-- Function: game/get_candidates.sql
-- --------------------------------------------------------------------------

-- Function: get_candidates
-- Category: game
-- Purpose: Orchestrate candidate filtering and apply business logic (scoring weights)
-- Returns: JSONB with candidates array and count for efficient reuse
CREATE OR REPLACE FUNCTION "public"."get_candidates" ("session_id_param" "uuid") returns TABLE ("candidates" JSONB, "count" INT) language "plpgsql" AS $$
DECLARE
  v_trait_threshold FLOAT;
  v_affirmed_match_weight FLOAT;
  v_affirmed_mismatch_weight FLOAT;
  v_denied_match_weight FLOAT;
  v_denied_mismatch_weight FLOAT;
  v_geo_fit_max_weight FLOAT;
  v_distance_normalization FLOAT;
BEGIN
  -- Get scoring configuration from settings
  SELECT value::FLOAT INTO v_trait_threshold FROM app_settings WHERE key = 'trait_similarity_threshold';
  SELECT value::FLOAT INTO v_affirmed_match_weight FROM app_settings WHERE key = 'weight_affirmed_trait_match';
  SELECT value::FLOAT INTO v_affirmed_mismatch_weight FROM app_settings WHERE key = 'weight_affirmed_trait_mismatch';
  SELECT value::FLOAT INTO v_denied_match_weight FROM app_settings WHERE key = 'weight_denied_trait_match';
  SELECT value::FLOAT INTO v_denied_mismatch_weight FROM app_settings WHERE key = 'weight_denied_trait_mismatch';
  SELECT value::FLOAT INTO v_geo_fit_max_weight FROM app_settings WHERE key = 'weight_geographic_fit_max';
  SELECT value::FLOAT INTO v_distance_normalization FROM app_settings WHERE key = 'geographic_distance_normalization';
  
  -- Validate all settings are present
  IF v_trait_threshold IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: trait_similarity_threshold'; END IF;
  IF v_affirmed_match_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_affirmed_trait_match'; END IF;
  IF v_affirmed_mismatch_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_affirmed_trait_mismatch'; END IF;
  IF v_denied_match_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_denied_trait_match'; END IF;
  IF v_denied_mismatch_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_denied_trait_mismatch'; END IF;
  IF v_geo_fit_max_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_geographic_fit_max'; END IF;
  IF v_distance_normalization IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: geographic_distance_normalization'; END IF;

  -- Orchestrate filtering and scoring pipeline
  RETURN QUERY
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
      gf.traits,
      ss.base_description_similarity,
      ss.affirmed_trait_similarity,
      ss.denied_trait_similarity,
      gf.distance_from_bbox_center,
      e.text AS description_text,
      (
        ss.base_description_similarity  -- Base similarity

        + CASE
            WHEN ss.affirmed_trait_similarity IS NOT NULL THEN
              -- Threshold-based weight: Does place HAVE affirmed trait?
              CASE
                WHEN ss.affirmed_trait_similarity > v_trait_threshold
                THEN v_affirmed_match_weight    -- Strong boost: place HAS affirmed trait
                ELSE v_affirmed_mismatch_weight -- Penalty: place doesn't have affirmed trait
              END
            ELSE 0.0
          END
        + CASE
            WHEN ss.denied_trait_similarity IS NOT NULL THEN
              -- Threshold-based weight: Does place HAVE denied trait?
              CASE
                WHEN ss.denied_trait_similarity > v_trait_threshold
                THEN v_denied_match_weight      -- Strong penalty: place HAS denied trait
                ELSE v_denied_mismatch_weight   -- Boost: place doesn't have denied trait
              END
            ELSE 0.0
          END
        + CASE
            WHEN gf.distance_from_bbox_center IS NOT NULL THEN
              -- Geographic fit bonus: closer to bbox center = higher bonus
              v_geo_fit_max_weight * (1 - LEAST(gf.distance_from_bbox_center / v_distance_normalization, 1.0))
            ELSE 0.0
          END
      ) AS confidence
    FROM geographic_filtered gf
    JOIN semantic_scored ss ON ss.place_id = gf.id
    JOIN embeddings e ON e.id = gf.embedding_id
  ),
  ranked_candidates AS (
    SELECT
      c.id,
      c.name,
      c.lat,
      c.lng,
      c.geom,
      c.traits,
      c.base_description_similarity,
      c.affirmed_trait_similarity,
      c.denied_trait_similarity,
      c.distance_from_bbox_center,
      c.description_text,
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
          'affirmed_trait_similarity', rc.affirmed_trait_similarity::FLOAT,
          'denied_trait_similarity', rc.denied_trait_similarity::FLOAT,
          'geographic_distance', rc.distance_from_bbox_center::FLOAT,
          'confidence', rc.confidence::FLOAT,
          'known_traits', COALESCE(SUBSTRING(rc.description_text FOR 300), '')
        ) ORDER BY rc.confidence DESC
      ),
      '[]'::JSONB
    ) AS candidates,
    (SELECT COUNT(*) FROM ranked_candidates)::INT AS count
  FROM ranked_candidates rc;
END;
$$;


ALTER FUNCTION "public"."get_candidates" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "public"."get_candidates" ("session_id_param" "uuid") IS 'Orchestrates candidate filtering and applies business logic (SOLID architecture).

Pipeline:
1. filter_geographic_candidates(session_id) → places + distance_from_bbox_center
2. Extract place IDs from geographic results
3. filter_semantic_candidates(session_id, place_ids[]) → similarity scores
4. Join geographic + semantic results
5. Apply business logic: threshold-based weights + composite scoring

Scoring formula (business logic - ALL VALUES CONFIGURABLE via app_settings):
- Base: base_description_similarity
- Affirmed trait: weight_affirmed_trait_match if similarity > trait_similarity_threshold, else weight_affirmed_trait_mismatch
- Denied trait: weight_denied_trait_match if similarity > trait_similarity_threshold, else weight_denied_trait_mismatch
- Geographic fit: weight_geographic_fit_max * (1 - distance/geographic_distance_normalization)

Configuration (from app_settings):
- trait_similarity_threshold (default 0.6): Threshold to determine if place "has" trait
- weight_affirmed_trait_match (default 0.3): Boost when place HAS affirmed trait
- weight_affirmed_trait_mismatch (default -0.2): Penalty when place does NOT have affirmed trait
- weight_denied_trait_match (default -0.4): Penalty when place HAS denied trait
- weight_denied_trait_mismatch (default 0.1): Boost when place does NOT have denied trait
- weight_geographic_fit_max (default 0.2): Maximum geographic fit bonus
- geographic_distance_normalization (default 20000000): Distance normalization (~20000km)

Filtering:
- Geographic: bbox inclusion/exclusion + wrong guess exclusion
- Semantic: base_description_similarity > semantic_similarity_threshold (default 0.5)
- NO LIMIT: Returns ALL candidates above threshold (count used by decide_next_turn)

Returns: TABLE(candidates JSONB, count INT)
- candidates: JSONB array of ALL candidates above threshold, ordered by confidence DESC
  Each candidate contains:
  - id, name, lat, lng: Basic place info
  - description_similarity: Raw base similarity (0-1)
  - affirmed_trait_similarity: Raw similarity to affirmed traits (0-1, null if none)
  - denied_trait_similarity: Raw similarity to denied traits (0-1, null if none)
  - geographic_distance: Distance in meters from bbox center (null if no bbox)
  - confidence: Final composite score with weights applied
- count: Actual count of qualifying candidates (used to decide when to guess)

Optimized: Returns JSONB directly to avoid repeated conversions.';

-- --------------------------------------------------------------------------
-- Function: game/get_question.sql
-- --------------------------------------------------------------------------

-- Function: get_question
-- Category: game
-- Chooses the best question using LLM intelligence
CREATE OR REPLACE FUNCTION "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) returns TABLE (
  "question_type" question_type,
  "trait_id" TEXT,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql AS $$
DECLARE
  v_geographic_questions JSONB;
  v_semantic_questions JSONB;
BEGIN
  -- Get 3 best geographic questions
  SELECT jsonb_agg(
    jsonb_build_object(
      'type', 'geographic',
      'region_id', q.region_id,
      'name', q.region_name
    )
  ) INTO v_geographic_questions
  FROM get_geographic_questions(p_session_id, p_candidates, 5) q;

  -- Pass to LLM for selection
  RETURN QUERY SELECT * FROM get_llm_question(p_session_id, p_candidates, COALESCE(v_geographic_questions, '[]'::jsonb));
END;
$$;


ALTER FUNCTION "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."get_question" ("p_session_id" UUID, "p_candidates" JSONB) IS 'Gets 3 geographic + 3 semantic questions and uses LLM to select the best one.

Returns: question_type, trait_id/geographic_region_id, question_text';

-- --------------------------------------------------------------------------
-- Function: game/handle_guess.sql
-- --------------------------------------------------------------------------

-- Function: handle_guess
-- Category: game
-- Purpose: Handle guess confirmation (SRP - Single Responsibility)
CREATE OR REPLACE FUNCTION "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) returns void language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_eliminated_place_id UUID;
  v_candidates JSONB;
  v_candidates_after JSONB;
BEGIN
  -- Correct guess - mark session as won
  IF p_answer = TRUE THEN
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
    FALSE,
    v_eliminated_place_id,
    NULL,
    v_candidates
  );

  -- Get candidates AFTER removing wrong guess (ONLY call to get_candidates)
  -- get_candidates excludes places with game_answers entries (question_id IS NULL)
  SELECT candidates
  INTO v_candidates_after
  FROM get_candidates(p_session_record.id);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) owner TO "postgres";


comment ON function "public"."handle_guess" ("p_answer" BOOLEAN, "p_session_record" record) IS 'Handle guess confirmation (YES/NO answer to a guess).

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
-- Function: game/handle_question.sql
-- --------------------------------------------------------------------------

-- Function: handle_question
-- Category: game
-- Purpose: Handle question answer (SRP - Single Responsibility)
CREATE OR REPLACE FUNCTION "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) returns void language plpgsql
SET
  search_path = public AS $$
DECLARE
  v_question_type question_type;
  v_trait_id TEXT;
  v_geographic_region_id UUID;
  v_question_text TEXT;
  v_candidates JSONB;
  v_candidates_after JSONB;
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

  -- Get candidates from next_turn (state at answer time - FREE!)
  v_candidates := p_session_record.next_turn->'candidates';

  -- Update trait state
  PERFORM apply_answer_to_session_state(
    p_session_record.id,
    p_answer,
    v_trait_id,
    v_geographic_region_id
  );

  -- Record answer with snapshot BEFORE calling get_candidates
  PERFORM record_game_answer(
    p_session_record.id,
    v_trait_id,
    v_geographic_region_id,
    p_answer,
    p_session_record.place_id,
    v_question_text,
    v_candidates
  );

  -- Get candidates AFTER recording answer
  SELECT candidates
  INTO v_candidates_after
  FROM get_candidates(p_session_record.id);

  -- Decide next turn (handles max_turns check)
  PERFORM decide_next_turn(p_session_record.id, v_candidates_after);
END;
$$;


ALTER FUNCTION "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) owner TO "postgres";


comment ON function "public"."handle_question" ("p_answer" BOOLEAN, "p_session_record" record) IS 'Handle question answer (YES/NO answer to a question).

Responsibilities (SRP):
- Fetch question details
- Apply answer based on question type (geographic/semantic)
- Record answer with snapshot at answer time
- Check if correct place survived
- Continue game

Storage strategy (no duplication):
- candidates: Retrieved from next_turn (state at answer time)
- Stored in game_answers once
- AFTER state stored in next next_turn (becomes BEFORE for next answer)
- No redundancy: Each state stored exactly once

Optimization: Only 1 get_candidates call per turn

Returns: VOID (raises exception on error)
Supports OCP: New question types can be added without modifying existing handlers.
Extracted from play_turn for Single Responsibility Principle.';

-- --------------------------------------------------------------------------
-- Function: game/play_turn.sql
-- --------------------------------------------------------------------------

-- Function: play_turn
-- Category: game
-- Purpose: Route turn processing to appropriate handler (SRP - Router pattern)
-- REFACTORED: Extracted handlers for SRP and OCP compliance
CREATE OR REPLACE FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" BOOLEAN) returns void language "plpgsql"
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_session_record RECORD;
BEGIN
  -- ============================================================================
  -- VALIDATION & SESSION RETRIEVAL
  -- ============================================================================
  
  IF p_session_id IS NULL OR p_answer IS NULL THEN
    RAISE EXCEPTION 'Parameters cannot be null';
  END IF;

  -- Get session details (only columns needed by handlers)
  SELECT
    id,
    place_id,
    was_correct,
    next_turn,
    description,
    affirmed_trait_ids,
    denied_trait_ids,
    description_embedding_id,
    affirmed_trait_embedding_id,
    denied_trait_embedding_id
  INTO v_session_record
  FROM game_sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
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


ALTER FUNCTION "public"."play_turn" ("p_session_id" "uuid", "p_answer" BOOLEAN) owner TO "postgres";


comment ON function "public"."play_turn" ("p_session_id" "uuid", "p_answer" BOOLEAN) IS 'Router function for processing game turns (SRP pattern).

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
-- Function: game/record_game_answer.sql
-- --------------------------------------------------------------------------

-- Function: record_game_answer
-- Category: game
-- Purpose: DRY helper for recording answers in game_answers table
CREATE OR REPLACE FUNCTION "public"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" BOOLEAN,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) returns void language plpgsql
SET
  search_path = public AS $$
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


ALTER FUNCTION "public"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" BOOLEAN,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "public"."record_game_answer" (
  "p_session_id" "uuid",
  "p_trait_id" TEXT,
  "p_geographic_region_id" "uuid",
  "p_answer" BOOLEAN,
  "p_place_id" "uuid",
  "p_question_text" TEXT,
  "p_candidates" JSONB
) IS 'Records answer with candidate snapshot at answer time.

Questions are generated on-the-fly from trait_id or geographic_region_id.';

-- --------------------------------------------------------------------------
-- Function: game/start_game.sql
-- --------------------------------------------------------------------------

-- Function: start_game
-- Category: game
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."start_game" (
  "p_description" "text",
  "p_language_code" "text" DEFAULT 'en'::"text"
) returns TABLE (session_id UUID) language "plpgsql"
SET
  search_path TO 'public' AS $$
DECLARE
  v_session_id uuid;
  v_candidates jsonb;
  v_description_embedding_id uuid;
BEGIN
  -- Rate limiting (anonymous users only)
  IF auth.role() = 'anonymous' THEN
    -- Advisory lock to prevent race condition (released at transaction end)
    PERFORM pg_advisory_xact_lock(hashtext(auth.uid()::text));
    
    IF EXISTS (
      SELECT 1 FROM game_sessions
      WHERE user_id = auth.uid()
      AND created_at > NOW() - INTERVAL '5 seconds'
    ) THEN
      RAISE EXCEPTION 'Rate limit exceeded: maximum 1 session per 5 seconds';
    END IF;
  END IF;

  -- Generate description embedding first
  v_description_embedding_id := get_or_create_embedding(p_description);
  
  -- Insert session with description embedding
  INSERT INTO game_sessions (
    user_id,
    description,
    description_language_code,
    description_embedding_id
  )
  VALUES (
    auth.uid(),
    p_description,
    p_language_code,
    v_description_embedding_id
  )
  RETURNING id INTO v_session_id;

  -- Get candidates
  SELECT candidates INTO v_candidates
  FROM get_candidates(v_session_id);

  -- Decide next turn
  PERFORM decide_next_turn(v_session_id, v_candidates);
  
  -- Return session_id
  RETURN QUERY SELECT v_session_id;
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
-- Function: maintenance/maintenance_cleanup.sql
-- --------------------------------------------------------------------------

-- Function: maintenance_cleanup
-- Category: maintenance
-- Deletes expired sessions and prunes question stats
CREATE OR REPLACE FUNCTION "public"."maintenance_cleanup" () returns "void" language "plpgsql" security definer AS $$
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
    FROM question_stats
    ORDER BY effectiveness_score DESC, times_asked ASC, created_at ASC
    OFFSET 450
  )
  DELETE FROM question_stats
  WHERE id IN (SELECT id FROM ranked);
END;
$$;


ALTER FUNCTION "public"."maintenance_cleanup" () owner TO "postgres";


comment ON function "public"."maintenance_cleanup" () IS 'Daily maintenance function that deletes expired sessions (24+ hours old)
and prunes question_stats to keep only the top 450 most effective ones.';

-- --------------------------------------------------------------------------
-- Function: maintenance/maintenance_weekly.sql
-- --------------------------------------------------------------------------

-- Function: maintenance_weekly
-- Category: maintenance
-- TODO: Update for trait-based system
CREATE OR REPLACE FUNCTION "public"."maintenance_weekly" () returns TABLE (
  "questions_duplicates_removed" INTEGER,
  "questions_kept" INTEGER,
  "places_duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer AS $$
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


ALTER FUNCTION "public"."maintenance_weekly" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- Function: places/add_place.sql
-- --------------------------------------------------------------------------

-- Function: add_place
-- Category: places
-- Adds a place to the database with geometry from Nominatim (Point, Polygon, or MultiPolygon)
CREATE OR REPLACE FUNCTION add_place (
  p_name TEXT,
  p_osm_id TEXT,
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL,
  p_geojson JSONB DEFAULT NULL,
  p_traits TEXT[] DEFAULT '{}'::TEXT[]
) returns UUID language plpgsql security definer
SET
  search_path = public AS $$
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
    traits
  )
  VALUES (
    p_name,
    p_osm_id,
    v_lat,
    v_lng,
    v_geom,
    p_traits
  )
  ON CONFLICT (osm_id) DO UPDATE SET
    name = EXCLUDED.name,
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    geom = EXCLUDED.geom,
    traits = EXCLUDED.traits,
    updated_at = NOW()
  RETURNING id INTO v_place_id;

  RETURN v_place_id;
END;
$$;


ALTER FUNCTION add_place (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, TEXT[]) owner TO postgres;


GRANT
EXECUTE ON function add_place (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, TEXT[]) TO authenticated,
anon;


comment ON function add_place (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, TEXT[]) IS 'Adds a place to the database with geometry from Nominatim.

Parameters:
- p_name: Place name
- p_osm_id: OpenStreetMap ID (unique)
- p_lat: Latitude (optional if geojson provided)
- p_lng: Longitude (optional if geojson provided)
- p_geojson: GeoJSON geometry from Nominatim (Point, Polygon, or MultiPolygon)
- p_traits: Array of trait IDs

Geometry handling:
- If geojson provided: uses actual geometry, calculates lat/lng from centroid if needed
- If only lat/lng provided: creates Point geometry
- Supports upsert on osm_id conflict

Returns: place_id (UUID)';

-- --------------------------------------------------------------------------
-- Function: places/approve_pending_place.sql
-- --------------------------------------------------------------------------

-- Function: approve_pending_place
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."approve_pending_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer AS $$
DECLARE
  v_place RECORD;
BEGIN
  -- Get place
  SELECT * INTO v_place FROM places WHERE id = p_place_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', p_place_id;
  END IF;

  IF NOT v_place.pending_review THEN
    RETURN jsonb_build_object('status', 'already_approved', 'place_id', p_place_id);
  END IF;

  -- Approve
  UPDATE places
  SET pending_review = FALSE
  WHERE id = p_place_id;

  -- Trigger will fire for enrichment

  RETURN jsonb_build_object('status', 'approved', 'place_id', p_place_id);
END;
$$;


ALTER FUNCTION "public"."approve_pending_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "public"."approve_pending_place" ("p_place_id" "uuid") IS 'Admin function to approve pending places submitted by anonymous users.';

-- --------------------------------------------------------------------------
-- Function: places/deduplicate_places.sql
-- --------------------------------------------------------------------------

-- Function: deduplicate_places
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."deduplicate_places" () returns TABLE (
  "duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
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


ALTER FUNCTION "public"."deduplicate_places" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- Function: places/enrich_place.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place
-- Category: places
-- TODO: Update to work with new trait-based system
CREATE OR REPLACE FUNCTION "public"."enrich_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer AS $$
BEGIN
  -- Stubbed out for now - needs refactoring for trait-based system
  RETURN jsonb_build_object('status', 'not_implemented');
END;
$$;


ALTER FUNCTION "public"."enrich_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "public"."enrich_place" ("p_place_id" "uuid") IS 'Stub - needs refactoring for trait-based system';

-- --------------------------------------------------------------------------
-- Function: places/match_places.sql
-- --------------------------------------------------------------------------

-- Function: match_places
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."match_places" (
  "query_embedding" "public"."vector",
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
) language "plpgsql" AS $$
DECLARE
  centroid_geom geometry;
  max_distance float;
  spatial_score float;
  effective_embedding vector(1024);
  bbox_min_x float;
  bbox_min_y float;
  bbox_max_x float;
  bbox_max_y float;
  exclude_bbox_min_x float;
  exclude_bbox_min_y float;
  exclude_bbox_max_x float;
  exclude_bbox_max_y float;
BEGIN
  effective_embedding := query_embedding;

  CREATE TEMP TABLE temp_candidates AS
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    p.descriptors,
    p.geom,
    1 - (p.embedding <=> effective_embedding) as sem_similarity
  FROM places p
  WHERE p.embedding IS NOT NULL
    AND p.geom IS NOT NULL
    AND 1 - (p.embedding <=> effective_embedding) > match_threshold
    -- TIGHTENED: Increased match_threshold from 0.20 to 0.25 to exclude lower-confidence candidates
    -- This ensures only semantically similar places are considered
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
  ORDER BY p.embedding <=> effective_embedding, p.id
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
-- Function: questions/get_geographic_questions.sql
-- --------------------------------------------------------------------------

-- Function: get_geographic_questions
-- Category: questions
-- Returns geographic regions to generate questions from, ranked by information gain
CREATE OR REPLACE FUNCTION "public"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER DEFAULT NULL
) returns TABLE (
  "region_id" "uuid",
  "region_name" "text",
  "region_level" "text",
  "effectiveness_score" DOUBLE PRECISION,
  "times_asked" INTEGER,
  "yes_count" INTEGER,
  "no_count" INTEGER,
  "information_gain" DOUBLE PRECISION
) language plpgsql AS $$
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
    AND ga.answer = TRUE
    AND ga.geographic_region_id IS NOT NULL;

  -- Get all confirmed regions as geometries for spatial filtering
  SELECT ARRAY_AGG(gr.geom)
  INTO v_confirmed_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = TRUE
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
    LEFT JOIN question_stats qs ON qs.geographic_region_id = gr.id
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
    rs.id,
    rs.name,
    rs.level,
    rs.effectiveness_score,
    rs.times_asked,
    rs.yes_count::INTEGER,
    rs.no_count::INTEGER,
    rs.information_gain
  FROM region_splits rs
  -- Order by information gain (best splits first), then effectiveness
  ORDER BY rs.information_gain DESC, rs.effectiveness_score DESC, rs.times_asked ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) owner TO "postgres";


comment ON function "public"."get_geographic_questions" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_limit" INTEGER
) IS 'Returns geographic regions to generate questions from (e.g., "Is it in {region_name}?").

CANDIDATE-AWARE: Uses actual place geometries (Point, Polygon, MultiPolygon) from candidates to calculate information gain.

Uses ST_Intersects for accurate geometry-based split calculation (works for all geometry types).

Filters by:
1. Level hierarchy: Must be deeper than shallowest confirmed level
2. Spatial intersection: Must intersect with confirmed regions
3. Not already asked in this session
4. MUST SPLIT CANDIDATES: Only returns regions where some candidates intersect and some don''t

Ranking:
1. information_gain (1.0 = perfect 50/50 split, 0.0 = useless question)
2. effectiveness_score (historical performance)
3. times_asked (prefer less-asked questions)

Progressive narrowing: continent → country

Returns: region info + yes_count, no_count, information_gain for analysis.
Questions are generated on-the-fly from region names, not stored.';

-- --------------------------------------------------------------------------
-- Function: questions/get_llm_question.sql
-- --------------------------------------------------------------------------

-- Function: get_llm_question
-- Category: questions
-- Purpose: Uses LLM to select the best question from available options
CREATE OR REPLACE FUNCTION "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) returns TABLE (
  "question_type" question_type,
  "trait_id" TEXT,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql security definer
SET
  search_path = public AS $$
DECLARE
  v_prompt_template TEXT;
  v_prompt TEXT;
  v_llm_response TEXT;
  v_response_json JSONB;
  v_selected_question_text TEXT;
  v_selected_region_idx INT;
  v_semantic_trait JSONB;
  v_question_reasoning TEXT;
  v_response_question_type TEXT;
  v_description TEXT;
  v_language_code TEXT;
  v_questions_internal_json JSONB;
  v_description_section TEXT := '';
  v_candidates_section TEXT := '';
  v_previous_answers_section TEXT := '';
  v_geo_section TEXT := '';
  v_rule3_text TEXT := '';
  v_geo_output_example TEXT := '';
  v_candidates_text TEXT;
BEGIN
  IF p_available_questions IS NULL THEN
    p_available_questions := '[]'::jsonb;
  END IF;


  -- ============================================================================
  -- BUILD GAME CONTEXT
  -- ============================================================================

  -- Get description and language code
  SELECT description, description_language_code INTO v_description, v_language_code
  FROM game_sessions
  WHERE id = p_session_id;

  -- Build candidate summary text (top 5)
  WITH ranked AS (
    SELECT
      ROW_NUMBER() OVER (ORDER BY (c->>'confidence')::float DESC) as row_num,
      c->>'name' as name,
      (c->>'confidence')::float as confidence,
      c->>'known_traits' as known_traits
    FROM jsonb_array_elements(p_candidates) c
  )
  SELECT string_agg(
    format('%s. %s; confidence %s%%',
      row_num,
      NULLIF(known_traits, ''),
      LEAST(100, GREATEST(0, round(confidence::numeric * 100)::int))
    ),
    E'\n'
    ORDER BY row_num
  )
  INTO v_candidates_text
  FROM ranked
  WHERE row_num <= 5;

  IF v_description IS NOT NULL THEN
    v_description_section := '# Initial Description' || E'\n' || v_description || E'\n';
  ELSE
    v_description_section := '';
  END IF;

  IF v_candidates_text IS NOT NULL THEN
    v_candidates_section := '# Top Candidates (format: "<rank>. <traits>; confidence <xx>%")' || E'\n' || v_candidates_text || E'\n';
  ELSE
    v_candidates_section := '';
  END IF;

  v_previous_answers_section := '';
  v_geo_section := '';

  -- ============================================================================
  -- BUILD QUESTION LIST JSON
  -- ============================================================================

  WITH enumerated AS (
    SELECT
      ROW_NUMBER() OVER () as option_idx,
      q,
      COALESCE(q->>'name', q->>'trait_clause', q->>'region_name', q->>'text') as display_name
    FROM jsonb_array_elements(p_available_questions) q
  )
  SELECT
    jsonb_agg(
      jsonb_build_object(
        'idx', option_idx,
        'region_id', q->>'region_id',
        'name', display_name
      ) ORDER BY option_idx
    ) AS internal_json,
    string_agg(
      format('%s: %s', option_idx, display_name),
      E'\n'
      ORDER BY option_idx
    ) AS geo_text
  INTO v_questions_internal_json, v_geo_section
  FROM enumerated;

  IF v_geo_section IS NOT NULL THEN
    v_geo_section := '# Geographic Regions' || E'\n' || v_geo_section || E'\n\n';
    v_rule3_text := '3. Only use the "Geographic Regions" section if you cannot find any semantic trait that would split the candidates into two reasonably balanced groups.';
    v_geo_output_example := 'If choosing a Geographic Option:' || E'\n' || '{"type": "geographic", "lang": "{language}", "question": "Is it in Europe?", "region_id": <int>, "reasoning": "<reasoning>"}' || E'\n';
  ELSE
    v_geo_section := '';
    v_rule3_text := '';
    v_geo_output_example := '';
  END IF;



  -- Build previous answers text
  WITH answer_history AS (
    SELECT
      ga.question_text,
      CASE WHEN ga.answer THEN 'TRUE' ELSE 'FALSE' END AS answer_text,
      ga.created_at
    FROM game_answers ga
    WHERE ga.session_id = p_session_id
      AND (ga.trait_id IS NOT NULL OR ga.geographic_region_id IS NOT NULL)
      AND ga.question_text IS NOT NULL
  )
  SELECT string_agg(
    format('- %s → %s', answer_history.question_text, answer_history.answer_text),
    E'\n'
    ORDER BY answer_history.created_at
  )
  INTO v_previous_answers_section
  FROM answer_history;

  IF v_previous_answers_section IS NOT NULL THEN
    v_previous_answers_section := '# Previous Answers' || E'\n' || v_previous_answers_section || E'\n\n';
  ELSE
    v_previous_answers_section := '';
  END IF;


  -- ==========================================================================
  -- BUILD PROMPT WITH CONTEXT
  -- ==========================================================================

  v_prompt_template := get_active_prompt();

  IF v_prompt_template IS NULL THEN
    RAISE EXCEPTION 'llm_prompt not configured in app_settings';
  END IF;

  v_prompt := replace(v_prompt_template, '{language}', COALESCE(v_language_code, 'en'));
  v_prompt := replace(v_prompt, '{rule3}', v_rule3_text);
  v_prompt := replace(v_prompt, '{geo_example}', v_geo_output_example);
  v_prompt := replace(v_prompt, '{description}', v_description_section);
  v_prompt := replace(v_prompt, '{candidates}', v_candidates_section);
  v_prompt := replace(v_prompt, '{answers}', v_previous_answers_section);
  v_prompt := replace(v_prompt, '{geographic_regions}', v_geo_section);


  -- ============================================================================
  -- CALL LLM AND PARSE JSON RESPONSE
  -- ============================================================================

  v_llm_response := call_llm_api(v_prompt);
  v_llm_response := trim(v_llm_response);

  IF v_llm_response LIKE '```%' THEN
    v_llm_response := regexp_replace(v_llm_response, '^```[^\n]*\n', '');
    v_llm_response := regexp_replace(v_llm_response, '\n```$', '');
    v_llm_response := trim(v_llm_response);
  END IF;

  IF v_llm_response = '' THEN
    RAISE EXCEPTION 'LLM returned empty response for prompt';
  END IF;

  BEGIN
    v_response_json := v_llm_response::jsonb;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'LLM response was not valid JSON: %', v_llm_response;
  END;

  v_response_question_type := lower(trim(COALESCE(v_response_json->>'type', v_response_json->>'question_type', '')));
  v_selected_region_idx := NULLIF(COALESCE(v_response_json->>'region_id', v_response_json->>'question_id'), '')::INT;
  v_selected_question_text := trim(COALESCE(v_response_json->>'question', v_response_json->>'question_text', ''));
  v_question_reasoning := NULLIF(trim(COALESCE(v_response_json->>'reasoning', '')),'');
  v_semantic_trait := v_response_json->'semantic_trait';

  IF v_semantic_trait IS NOT NULL THEN
    IF jsonb_typeof(v_semantic_trait) = 'string' THEN
      v_semantic_trait := jsonb_build_object('canonical_name', v_semantic_trait #>> '{}');
    END IF;
    IF (v_semantic_trait ? 'canonical_name') THEN
      IF NOT (v_semantic_trait ? 'slug') OR (v_semantic_trait->>'slug') IS NULL OR v_semantic_trait->>'slug' = '' THEN
        v_semantic_trait := v_semantic_trait || jsonb_build_object(
          'slug', regexp_replace(lower(v_semantic_trait->>'canonical_name'), '[^a-z0-9]+', '_', 'g')
        );
      END IF;
    END IF;
  END IF;


  IF v_selected_question_text = '' THEN
    v_selected_question_text := NULL;
  END IF;

  IF v_selected_question_text IS NOT NULL AND v_selected_question_text NOT LIKE '%?' THEN
    v_selected_question_text := v_selected_question_text || '?';
  END IF;

  RAISE NOTICE 'LLM response JSON: %', v_response_json;

  -- ============================================================================
  -- FIND SELECTED QUESTION BY ID (LLM must return question_id for existing prompts)
  -- ============================================================================

  IF v_response_question_type = 'geographic' THEN
    IF v_selected_region_idx IS NULL THEN
      RAISE EXCEPTION 'LLM geographic response missing region_id: %', v_response_json;
    END IF;
    IF v_selected_question_text IS NULL THEN
      RAISE EXCEPTION 'LLM geographic response missing question text: %', v_response_json;
    END IF;

    RETURN QUERY
    SELECT
      'geographic'::question_type,
      NULL::text,
      (q->>'region_id')::uuid,
      v_selected_question_text,
      v_question_reasoning
    FROM jsonb_array_elements(v_questions_internal_json) q
    WHERE (q->>'idx')::int = v_selected_region_idx
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'LLM returned invalid region_id % (available: 1-%). Response: %',
        v_selected_region_idx,
        jsonb_array_length(v_questions_internal_json),
        v_response_json;
    END IF;

    RETURN;

  ELSIF v_response_question_type = 'semantic' THEN
    IF v_selected_question_text IS NULL THEN
      RAISE EXCEPTION 'LLM semantic response missing question_text: %', v_response_json;
    END IF;

    DECLARE
      v_trait_clause TEXT;
      v_trait_id TEXT;
      v_trait_slug TEXT;
    BEGIN
      IF v_semantic_trait IS NULL THEN
        RAISE EXCEPTION 'LLM semantic question missing semantic_trait metadata: %', v_llm_response;
      END IF;

      v_trait_clause := trim(COALESCE(v_semantic_trait->>'canonical_name', ''));

      IF v_trait_clause = '' THEN
        RAISE EXCEPTION 'LLM semantic question missing canonical_name in semantic_trait: %', v_llm_response;
      END IF;

      v_trait_slug := trim(COALESCE(v_semantic_trait->>'slug', ''));

      IF v_trait_slug = '' THEN
        v_trait_slug := regexp_replace(lower(v_trait_clause), '[^a-z0-9]+', '_', 'g');
      ELSE
        v_trait_slug := regexp_replace(lower(v_trait_slug), '[^a-z0-9_]', '_', 'g');
      END IF;

      IF v_trait_slug = '' THEN
        RAISE EXCEPTION 'LLM semantic question produced invalid slug in semantic_trait: %', v_llm_response;
      END IF;

      v_trait_id := 'llm_' || v_trait_slug;

      RAISE NOTICE 'LLM invented new trait: "%" with ID: %', v_trait_clause, v_trait_id;

      INSERT INTO place_traits (id, clause, category)
      VALUES (v_trait_id, v_trait_clause, 'llm_invented')
      ON CONFLICT (id) DO UPDATE SET clause = EXCLUDED.clause;

      RETURN QUERY
      SELECT
        'semantic'::question_type,
        v_trait_id,
        NULL::uuid,
        v_selected_question_text,
        v_question_reasoning;
    END;

    RETURN;
  ELSE
    RAISE EXCEPTION 'LLM response contained invalid question_type: %', v_response_json;
  END IF;

END;
$$;


ALTER FUNCTION "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) owner TO "postgres";


comment ON function "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) IS 'Uses LLM to select best question from available options.

SECURITY DEFINER: Needs elevated privileges to INSERT invented traits into place_traits.
Session ownership is validated by calling functions (play_turn, etc).

Process:
1. Build human-readable game context (description, candidates, previous answers, geo options)
2. Call LLM via call_llm_api
3. Parse JSON response (question_type + question_text + optional semantic_trait)
4. Match response to enumerated questions for geographic selections
5. For semantic questions: ensure trait metadata, persist trait in place_traits, and return new question

Returns: question_type, trait_id/geographic_region_id, question_text';

-- --------------------------------------------------------------------------
-- Function: questions/get_semantic_questions.sql
-- --------------------------------------------------------------------------

-- Function: get_semantic_questions
-- Category: questions
-- Returns traits to generate semantic questions from
CREATE OR REPLACE FUNCTION "public"."get_semantic_questions" (
  "p_session_id" "uuid",
  "p_limit" INTEGER DEFAULT NULL
) returns TABLE (
  "trait_id" TEXT,
  "trait_clause" TEXT,
  "trait_category" TEXT,
  "effectiveness_score" DOUBLE PRECISION,
  "times_asked" INTEGER
) language plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    pt.id,
    pt.clause,
    pt.category,
    COALESCE(qs.effectiveness_score, 0.5) as effectiveness_score,
    COALESCE(qs.times_asked, 0) as times_asked
  FROM place_traits pt
  LEFT JOIN question_stats qs ON qs.trait_id = pt.id
  WHERE
    -- Don't ask same trait twice
    pt.id NOT IN (
      SELECT ga.trait_id
      FROM game_answers ga
      WHERE ga.session_id = p_session_id
        AND ga.trait_id IS NOT NULL
    )
  ORDER BY effectiveness_score DESC, times_asked ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_semantic_questions" ("p_session_id" "uuid", "p_limit" INTEGER) owner TO "postgres";


comment ON function "public"."get_semantic_questions" ("p_session_id" "uuid", "p_limit" INTEGER) IS 'Returns traits to generate semantic questions from (e.g., "Does it have {trait_clause}?").

Filters by:
1. Not already asked in this session

Orders by:
1. Effectiveness score (descending)
2. Times asked (ascending)

Questions are generated on-the-fly from trait clauses, not stored.';

-- --------------------------------------------------------------------------
-- Function: questions/update_question_effectiveness_batch.sql
-- --------------------------------------------------------------------------

-- Function: update_question_effectiveness_batch
-- Category: questions
-- Updates question_stats based on game performance
CREATE OR REPLACE FUNCTION "public"."update_question_effectiveness_batch" ("session_id_param" "uuid") returns "void" language "plpgsql" security definer AS $$
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

    -- Find or create question_stats entry
    IF v_question_type = 'semantic' THEN
      SELECT id INTO v_stat_id
      FROM question_stats
      WHERE trait_id = answer_record.trait_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO question_stats (question_type, trait_id)
        VALUES ('semantic', answer_record.trait_id)
        RETURNING id INTO v_stat_id;
      END IF;
    ELSE
      SELECT id INTO v_stat_id
      FROM question_stats
      WHERE geographic_region_id = answer_record.geographic_region_id;
      
      IF v_stat_id IS NULL THEN
        INSERT INTO question_stats (question_type, geographic_region_id)
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
    FROM question_stats
    WHERE id = v_stat_id;

    new_effectiveness_score := new_effectiveness_score + score_delta;

    -- Clamp to valid range [0.0, 1.0]
    new_effectiveness_score := LEAST(1.0, GREATEST(0.0, new_effectiveness_score));

    -- Update the stats
    UPDATE question_stats
    SET
      times_asked = times_asked + 1,
      effectiveness_score = new_effectiveness_score
    WHERE id = v_stat_id;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."update_question_effectiveness_batch" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "public"."update_question_effectiveness_batch" ("session_id_param" "uuid") IS 'Enhanced effectiveness update for v2 using precision-gain formula from PRD.
Formula:
  precision_gain = (before - after) / greatest(1, before)
  survival = CASE WHEN correct_place_survived THEN 1 ELSE -1 END
  score_delta = 0.04 * precision_gain * survival
  IF precision_gain >= 0.30 AND survival = 1 THEN score_delta += 0.01
  IF precision_gain < 0.05 THEN score_delta -= 0.02
  effectiveness_score = clamp(effectiveness_score + score_delta, 0.0, 1.0)

Also increments times_asked for each question used in the session.';

-- --------------------------------------------------------------------------
-- Function: utilities/apply_metadata_filter.sql
-- --------------------------------------------------------------------------

-- Function: apply_metadata_filter
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN DEFAULT TRUE
) returns BOOLEAN language "plpgsql" AS $$
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


ALTER FUNCTION "public"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN
) owner TO "postgres";


comment ON function "public"."apply_metadata_filter" (
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
-- Function: utilities/approve_pending_session.sql
-- --------------------------------------------------------------------------

-- Function: approve_pending_session
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."approve_pending_session" () returns "trigger" language "plpgsql" security definer AS $$
DECLARE
  place_id_val UUID;
BEGIN
  -- Only fire when pending_review becomes false and submitted_nominatim_id is not null
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE AND NEW.submitted_nominatim_id IS NOT NULL THEN
    -- Upsert into places by nominatim_place_id
    INSERT INTO places (
      name, lat, lng, nominatim_place_id,
      canonical_description, semantic_constraint,
      language_code, geom
    )
    VALUES (
      NEW.submitted_place_name,
      NEW.submitted_lat,
      NEW.submitted_lng,
      NEW.submitted_nominatim_id,
      NEW.description,
      NEW.semantic_constraint,
      NEW.description_language_code,
      ST_SetSRID(ST_MakePoint(NEW.submitted_lng, NEW.submitted_lat), 4326)
    )
    ON CONFLICT (nominatim_place_id)
    DO UPDATE SET
      canonical_description = COALESCE(EXCLUDED.canonical_description, places.canonical_description),
      semantic_constraint = COALESCE(EXCLUDED.semantic_constraint, places.semantic_constraint),
      descriptors = COALESCE(places.descriptors, '{}'::jsonb),
      updated_at = NOW()
    RETURNING id INTO place_id_val;

    -- Update place embedding if session has description_embedding
    IF NEW.description_embedding IS NOT NULL THEN
      PERFORM update_place_embedding(place_id_val, NEW.description_embedding);
    END IF;

    -- Update session with place_id (status is calculated from was_correct)
    UPDATE game_sessions
    SET place_id = place_id_val
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."approve_pending_session" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- Function: utilities/build_guess_turn.sql
-- --------------------------------------------------------------------------

-- Function: build_guess_turn
-- Category: utilities
-- Purpose: Pure function to build guess next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) returns JSONB language "plpgsql" immutable AS $$
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


ALTER FUNCTION "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) IS 'Pure function to build guess next_turn JSONB.

IMMUTABLE: Same inputs always produce same output (no side effects).

Extracted from decide_next_turn for Single Responsibility Principle.';

-- --------------------------------------------------------------------------
-- Function: utilities/build_question_turn.sql
-- --------------------------------------------------------------------------

-- Function: build_question_turn
-- Category: utilities
-- Purpose: Pure function to build question next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) returns JSONB language plpgsql immutable AS $$
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


ALTER FUNCTION "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
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
-- Function: utilities/call_llm_api.sql
-- --------------------------------------------------------------------------

-- Function: call_llm_api
-- Category: utilities
-- Purpose: Call LLM via edge function with a prompt
-- Returns: LLM response text
CREATE OR REPLACE FUNCTION "public"."call_llm_api" ("p_prompt" "text", "p_format" "text" DEFAULT NULL) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  extensions AS $$
DECLARE
  v_response extensions.http_response;
  v_edge_function_url TEXT;
  v_anon_key TEXT;
  v_llm_response TEXT;
  v_request_body JSONB;
  v_llm_model TEXT;
  v_llm_options JSONB;
  v_llm_temperature FLOAT;
  v_llm_num_predict INT;
  v_llm_top_p FLOAT;
  v_llm_stop JSONB;
BEGIN
  -- Increase statement timeout for slower LLM responses (default 5s is too short)
  PERFORM set_config('statement_timeout', '15s', true);
  -- Increase HTTP timeout (default 5s) so curl waits for Ollama
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '15000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '5000');
  -- ============================================================================
  -- CONFIGURATION
  -- ============================================================================
  v_edge_function_url := COALESCE(
    current_setting('app.supabase_url', true),
    'http://host.docker.internal:54321'
  ) || '/functions/v1/call-llm';

  v_anon_key := COALESCE(
    current_setting('app.supabase_anon_key', true),
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
  );

  -- ============================================================================
  -- FETCH LLM SETTINGS FROM app_settings (FAIL if missing)
  -- ============================================================================
  SELECT value INTO STRICT v_llm_model FROM app_settings WHERE key = 'llm_model';
  SELECT value::FLOAT INTO STRICT v_llm_temperature FROM app_settings WHERE key = 'llm_temperature';
  SELECT value::INT INTO STRICT v_llm_num_predict FROM app_settings WHERE key = 'llm_num_predict';
  SELECT value::FLOAT INTO STRICT v_llm_top_p FROM app_settings WHERE key = 'llm_top_p';
  SELECT value::JSONB INTO STRICT v_llm_stop FROM app_settings WHERE key = 'llm_stop';

  -- Build options object
  v_llm_options := jsonb_build_object(
    'temperature', v_llm_temperature,
    'num_predict', v_llm_num_predict,
    'top_p', v_llm_top_p,
    'stop', v_llm_stop
  );

  -- Build request body
  v_request_body := jsonb_build_object(
    'prompt', p_prompt,
    'model', v_llm_model,
    'options', v_llm_options
  );
  
  IF p_format IS NOT NULL THEN
    v_request_body := v_request_body || jsonb_build_object('format', p_format);
  END IF;

  RAISE NOTICE 'Calling call-llm at: %', v_edge_function_url;

  -- ============================================================================
  -- HTTP CALL TO EDGE FUNCTION
  -- ============================================================================
  -- Note: http extension timeout is set globally in PostgreSQL config
  SELECT * INTO v_response FROM extensions.http((
    'POST',
    v_edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    v_request_body::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', v_response.status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================
  IF v_response.status != 200 THEN
    RAISE EXCEPTION 'LLM call failed with status %: %', v_response.status, v_response.content;
  END IF;

  -- Parse LLM response
  v_llm_response := (v_response.content::jsonb->>'response')::text;

  RETURN v_llm_response;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'LLM API call failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."call_llm_api" ("p_prompt" "text", "p_format" "text") owner TO "postgres";


comment ON function "public"."call_llm_api" ("p_prompt" "text", "p_format" "text") IS 'Call LLM via call-llm edge function with database-driven configuration.

Fetches LLM settings from app_settings and passes them to the edge function.

Parameters:
- p_prompt: The prompt to send to the LLM
- p_format: Optional format hint (e.g., "json" for JSON responses)

Returns: LLM response text

Configuration (from app_settings - REQUIRED):
- llm_model: Ollama model name
- llm_temperature: Temperature 0.0-1.0
- llm_num_predict: Max tokens to generate
- llm_top_p: Top-p sampling 0.0-1.0
- llm_stop: JSON array of stop sequences
- Uses current_setting(''app.supabase_url'', true) with fallback to local dev
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Error handling:
- Raises exception if any required app_settings are missing
- Raises exception on HTTP error
- Raises exception on parsing failure';

-- --------------------------------------------------------------------------
-- Function: utilities/enrich_place_on_approval.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place_on_approval
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."enrich_place_on_approval" () returns "trigger" language "plpgsql" AS $$
BEGIN
  -- Only fire when pending_review becomes FALSE
  IF OLD.pending_review = TRUE AND NEW.pending_review = FALSE THEN
    -- Run enrichment
    PERFORM enrich_place(NEW.id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."enrich_place_on_approval" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- Function: utilities/enrich_place_on_session_complete.sql
-- --------------------------------------------------------------------------

-- Function: enrich_place_on_session_complete
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."enrich_place_on_session_complete" () returns "trigger" language "plpgsql" AS $$
BEGIN
  -- Only fire when was_correct becomes TRUE
  IF NEW.was_correct = TRUE AND (OLD.was_correct IS NULL OR OLD.was_correct = FALSE) THEN
    -- Run enrichment asynchronously (don't block session completion)
    PERFORM enrich_place(NEW.place_id);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."enrich_place_on_session_complete" () owner TO "postgres";

-- --------------------------------------------------------------------------
-- Function: utilities/generate_embedding.sql
-- --------------------------------------------------------------------------

-- Function: generate_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."generate_embedding" ("p_text" "text") returns "public"."vector" language "plpgsql" security definer
SET
  search_path = public,
  extensions AS $$
DECLARE
  response extensions.http_response;
  edge_function_url TEXT;
  validated_text TEXT;
  embedding_vector vector(1024);
  v_anon_key TEXT;
BEGIN
  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================

  -- Validate text input (max 1000 chars, min 1 char after trim)
  validated_text := validate_user_input(p_text, 1000, 'embedding_text');

  -- ============================================================================
  -- CONFIGURATION RETRIEVAL
  -- ============================================================================

  -- Get Supabase URL from settings (with fallback for local development)
  edge_function_url := COALESCE(
    current_setting('app.supabase_url', true),
    'http://host.docker.internal:54321'
  ) || '/functions/v1/generate-embedding';

  -- Get anon key from settings (with fallback for local development)
  v_anon_key := COALESCE(
    current_setting('app.supabase_anon_key', true),
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
  );

  RAISE NOTICE 'Calling generate-embedding at: %', edge_function_url;

  -- ============================================================================
  -- EDGE FUNCTION CALL (SYNCHRONOUS HTTP)
  -- ============================================================================

  -- Make synchronous HTTP request using http extension
  -- Note: http extension timeout is set globally, not per-request
  SELECT * INTO response FROM extensions.http((
    'POST',
    edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    jsonb_build_object('text', validated_text)::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', response.status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================

  -- Check for success
  IF response.status != 200 THEN
    RAISE EXCEPTION 'Embedding generation failed with status %: %', response.status, response.content;
  END IF;

  -- Parse the embedding from response
  embedding_vector := (response.content::jsonb->>'embedding')::vector(1024);

  IF embedding_vector IS NULL THEN
    RAISE EXCEPTION 'Response did not contain valid embedding: %', response.content;
  END IF;

  RETURN embedding_vector;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'Embedding generation failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."generate_embedding" ("p_text" "text") owner TO "postgres";


comment ON function "public"."generate_embedding" ("p_text" "text") IS 'Generates a 1024-dimensional embedding vector for the given text with input validation.
Parameters:
- p_text: text to embed (validated: 1-1000 chars, no control chars)

Security:
- Validates input via validate_user_input()
- Prevents injection attacks via control character detection
- Enforces length limits
- Uses Authorization header with anon key

Configuration:
- Uses current_setting(''app.supabase_url'', true) with fallback to ''http://host.docker.internal:54321''
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Process:
1. Validates input text
2. Calls edge function (generate-embedding) via synchronous http extension
3. Parses and returns vector(1024)

Error handling:
- Raises exception on validation failure
- Raises exception on HTTP error
- Raises exception on parsing failure

Technical:
- Uses http extension (synchronous) for reliability in local and production environments
- Authorization header required for edge function infrastructure';

-- --------------------------------------------------------------------------
-- Function: utilities/geo_region_for.sql
-- --------------------------------------------------------------------------

-- Function: geo_region_for
-- Category: utilities
-- Purpose: Map geographic feature values to standard bounding boxes (SRID 4326)
-- Returns JSONB with bbox array [min_lat, max_lat, min_lng, max_lng]
CREATE OR REPLACE FUNCTION "public"."geo_region_for" ("p_feature_value" "text") returns "jsonb" language plpgsql security definer
SET
  search_path = public AS $$
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


ALTER FUNCTION "public"."geo_region_for" ("p_feature_value" "text") owner TO "postgres";


comment ON function "public"."geo_region_for" ("p_feature_value" "text") IS 'Maps geographic feature values to standard bounding boxes (SRID 4326).

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
-- Function: utilities/get_active_prompt.sql
-- --------------------------------------------------------------------------

-- Function: get_active_prompt
-- Category: utilities
-- Returns the active system prompt from app_settings
CREATE OR REPLACE FUNCTION "public"."get_active_prompt" () returns TEXT language plpgsql security definer
SET
  search_path = public AS $$
DECLARE
  v_prompt TEXT;
BEGIN
  -- Fetch the system prompt
  SELECT value INTO v_prompt
  FROM app_settings
  WHERE key = 'llm_prompt'
  LIMIT 1;

  -- Return the prompt, or NULL if not configured
  RETURN v_prompt;
END;
$$;


ALTER FUNCTION "public"."get_active_prompt" () owner TO "postgres";


comment ON function "public"."get_active_prompt" () IS 'Retrieves system prompt from app_settings (key: llm_prompt).

Returns NULL if no prompt is configured.
Used by LLM-calling functions to fetch DB-configurable prompt.
Prompt supports placeholders like {question_list} which are replaced by the caller.';

-- --------------------------------------------------------------------------
-- Function: utilities/get_max_turns.sql
-- --------------------------------------------------------------------------

-- Function: get_max_turns
-- Category: utilities
-- Purpose: Get max_turns setting from app_settings (DRY helper)
CREATE OR REPLACE FUNCTION "public"."get_max_turns" () returns INTEGER language sql stable
SET
  search_path = public AS $$
  SELECT COALESCE((value)::INT, 5)
  FROM app_settings
  WHERE key = 'max_turns';
$$;


ALTER FUNCTION "public"."get_max_turns" () owner TO "postgres";


comment ON function "public"."get_max_turns" () IS 'Get max_turns from app_settings table.
Returns 5 if setting not found.
Marked STABLE for query optimization.';

-- --------------------------------------------------------------------------
-- Function: utilities/get_or_create_embedding.sql
-- --------------------------------------------------------------------------

-- Function: get_or_create_embedding
-- Category: utilities
-- Gets existing embedding ID or creates new one if not found
CREATE OR REPLACE FUNCTION "public"."get_or_create_embedding" ("p_text" "text") returns UUID language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_text_hash text;
  v_embedding_id uuid;
  v_embedding vector(1024);
BEGIN
  -- Generate SHA256 hash of text
  v_text_hash := encode(extensions.digest(p_text, 'sha256'), 'hex');

  -- Try to find existing embedding by hash
  SELECT id INTO v_embedding_id
  FROM embeddings
  WHERE text_hash = v_text_hash;

  -- If found, return existing ID
  IF v_embedding_id IS NOT NULL THEN
    RETURN v_embedding_id;
  END IF;

  -- If not found, generate and store new embedding
  v_embedding := generate_embedding(p_text);

  INSERT INTO embeddings (text, text_hash, embedding)
  VALUES (p_text, v_text_hash, v_embedding)
  RETURNING id INTO v_embedding_id;

  RETURN v_embedding_id;
END;
$$;


ALTER FUNCTION "public"."get_or_create_embedding" ("p_text" "text") owner TO "postgres";


comment ON function "public"."get_or_create_embedding" ("p_text" "text") IS 'Gets existing embedding ID by text hash, or generates and stores new one if not found.

Process:
1. Hash the input text (SHA256)
2. Look up existing embedding by hash
3. If found, return existing ID (cached)
4. If not found, call edge function to generate embedding
5. Store new embedding in database
6. Return new ID

Returns: embedding UUID';

-- --------------------------------------------------------------------------
-- Function: utilities/update_embedding.sql
-- --------------------------------------------------------------------------

-- Function: update_embedding
-- Category: utilities
-- Updates existing embedding with new text
CREATE OR REPLACE FUNCTION "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") returns void language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_new_embedding vector(1024);
  v_new_text_hash text;
BEGIN
  -- Generate SHA256 hash of new text
  v_new_text_hash := encode(digest(p_new_text, 'sha256'), 'hex');

  -- Generate new embedding
  v_new_embedding := generate_embedding(p_new_text);

  -- Update embedding record
  UPDATE embeddings
  SET
    text = p_new_text,
    text_hash = v_new_text_hash,
    embedding = v_new_embedding,
    updated_at = now()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Embedding with ID % not found', p_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") owner TO "postgres";


comment ON function "public"."update_embedding" ("p_id" UUID, "p_new_text" "text") IS 'Updates existing embedding with new text. Regenerates embedding and updates hash.';

-- --------------------------------------------------------------------------
-- Function: utilities/update_place_embedding.sql
-- --------------------------------------------------------------------------

-- Function: update_place_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION DEFAULT 0.3
) returns "void" language "plpgsql" security definer AS $$
DECLARE
  current_embedding vector(768);
  current_count int;
  weight float;
BEGIN
  SELECT embedding, times_encountered INTO current_embedding, current_count
  FROM places
  WHERE id = place_id_param;

  IF current_embedding IS NULL THEN
    UPDATE places
    SET
      embedding = new_embedding,
      times_encountered = times_encountered + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  weight := learning_rate / (1.0 + current_count * 0.1);

  UPDATE places
  SET
    embedding = (
      SELECT array_agg(
        (1.0 - weight) * old_val + weight * new_val
      )::vector(768)
      FROM unnest(current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val)
    ),
    times_encountered = times_encountered + 1
  WHERE id = place_id_param;
END;
$$;


ALTER FUNCTION "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION
) owner TO "postgres";


comment ON function "public"."update_place_embedding" (
  "place_id_param" "uuid",
  "new_embedding" "public"."vector",
  "learning_rate" DOUBLE PRECISION
) IS 'Enhanced for v2: uses times_encountered instead of game_count.
Updates a place''s embedding using weighted average. Weight decreases as times_encountered increases.
Uses 768-dimensional vectors for nomic-embed-text model.
After update, bumps times_encountered counter.';

-- --------------------------------------------------------------------------
-- Function: utilities/validate_user_input.sql
-- --------------------------------------------------------------------------

-- Function: validate_user_input
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text" DEFAULT 'input'
) returns "text" language "plpgsql" security definer
SET
  search_path = public AS $$
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


ALTER FUNCTION "public"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text"
) owner TO "postgres";


comment ON function "public"."validate_user_input" (
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
-- Trigger: 05_triggers.sql
-- --------------------------------------------------------------------------

-- ============================================================================
-- Database Triggers
-- ============================================================================
-- Description: Trigger definitions that call trigger functions
-- Dependencies: Tables (02_tables.sql), Trigger Functions (supabase/db/functions/utilities/)
-- Note: Trigger functions are defined in supabase/db/functions/utilities/
-- ============================================================================
DROP TRIGGER if EXISTS "enrich_place_on_session_complete_trigger" ON "public"."game_sessions";


CREATE TRIGGER "enrich_place_on_session_complete_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW
EXECUTE function "public"."enrich_place_on_session_complete" ();


comment ON trigger "enrich_place_on_session_complete_trigger" ON "public"."game_sessions" IS 'Triggers place enrichment when a session completes successfully (was_correct = TRUE).';


-- ============================================================================
-- Function-Level Security (EXECUTE Permissions)
-- ============================================================================
-- Description: Control which functions can be called directly by users
-- vs which are internal-only (called by other functions)
-- Note: This section must come AFTER all functions are defined
-- ============================================================================
-- ============================================================================
-- generate_embedding - INTERNAL ONLY
-- ============================================================================
-- This function should ONLY be called by other database functions (start_game, etc.)
-- NOT directly from the frontend, to prevent API quota abuse.
-- Rate limiting is enforced at the entry points (start_game, etc.)
REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  public;


REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  anon;


REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  authenticated;


-- Only postgres role and service_role can execute
GRANT
EXECUTE ON function public.generate_embedding (TEXT) TO postgres;


GRANT
EXECUTE ON function public.generate_embedding (TEXT) TO service_role;

