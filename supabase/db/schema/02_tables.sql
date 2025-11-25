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
