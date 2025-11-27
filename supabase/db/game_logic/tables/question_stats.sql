-- Table: question_stats
-- Schema: game_logic
-- Description: Tracks effectiveness of questions (internal analytics)
CREATE TABLE IF NOT EXISTS "game_logic"."question_stats" (
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
