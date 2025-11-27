-- Table: place_traits
-- Schema: public
-- Description: Links places to traits
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."place_traits" (
  "place_id" UUID NOT NULL,
  "trait_id" TEXT NOT NULL,
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
