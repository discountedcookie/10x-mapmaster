-- Table: geographic_regions
-- Schema: public
-- Description: Geographic regions (continents and countries) from Natural Earth
-- Used to generate geographic questions dynamically
-- Table Definition
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
