-- Table: place_trait_links
-- Schema: public
-- Description: Links places to traits while tracking provenance for enrichment sources
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."place_trait_links" (
  "place_id" UUID NOT NULL,
  "trait_id" TEXT NOT NULL,
  "source_type" TEXT NOT NULL DEFAULT 'nominatim'::TEXT,
  "source_metadata" JSONB DEFAULT '{}'::JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  CONSTRAINT "place_trait_links_source_type_check" CHECK (char_length(btrim("source_type")) > 0)
);


ALTER TABLE "public"."place_trait_links" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_pkey" PRIMARY KEY ("place_id", "trait_id");


-- Foreign Keys
ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."place_trait_links"
ADD CONSTRAINT "place_trait_links_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."place_traits" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_place_trait_links_trait_id" ON "public"."place_trait_links" ("trait_id");


-- RLS Policies
ALTER TABLE "public"."place_trait_links" enable ROW level security;


DROP POLICY if EXISTS "Place trait links viewable by everyone" ON "public"."place_trait_links";


DROP POLICY if EXISTS "Service role can manage place trait links" ON "public"."place_trait_links";


CREATE POLICY "Place trait links viewable by everyone" ON "public"."place_trait_links" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place trait links" ON "public"."place_trait_links" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."place_trait_links" IS 'Associates places with traits plus provenance details describing how/why the trait was assigned.';
