-- Table: question_stats
-- Schema: public
-- Description: Tracks effectiveness of questions (generated on-the-fly from traits/regions)
-- Table Definition
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


-- Primary Key
ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_pkey" PRIMARY KEY ("id");


-- Foreign Keys
ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."place_traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."question_stats"
ADD CONSTRAINT "question_stats_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "public"."geographic_regions" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_question_stats_trait_id" ON "public"."question_stats" ("trait_id");


CREATE INDEX if NOT EXISTS "idx_question_stats_geographic_region_id" ON "public"."question_stats" ("geographic_region_id");


-- RLS Policies
ALTER TABLE "public"."question_stats" enable ROW level security;


DROP POLICY if EXISTS "Question stats viewable by everyone" ON "public"."question_stats";


DROP POLICY if EXISTS "Service role can manage question stats" ON "public"."question_stats";


CREATE POLICY "Question stats viewable by everyone" ON "public"."question_stats" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage question stats" ON "public"."question_stats" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."question_stats" IS 'Tracks effectiveness of questions. Questions are generated on-the-fly from traits/regions, not stored as text.';


comment ON COLUMN "public"."question_stats"."trait_id" IS 'Reference to place_traits for semantic questions';


comment ON COLUMN "public"."question_stats"."geographic_region_id" IS 'Reference to geographic_regions for geographic questions';
