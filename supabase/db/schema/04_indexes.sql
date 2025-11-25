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
