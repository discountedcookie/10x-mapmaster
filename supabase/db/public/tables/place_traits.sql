-- Table: place_traits
-- Schema: public
-- Description: Canonical trait definitions used to describe and filter places
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."place_traits" (
  "id" TEXT NOT NULL,
  "clause" TEXT NOT NULL,
  "category" TEXT NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."place_traits" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."place_traits"
ADD CONSTRAINT "place_traits_pkey" PRIMARY KEY ("id");


-- Indexes
CREATE INDEX if NOT EXISTS "idx_place_traits_category" ON "public"."place_traits" ("category");


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
comment ON TABLE "public"."place_traits" IS 'Canonical trait vocabulary. Each trait provides a short descriptive clause that can be embedded or composed into constraints.';
