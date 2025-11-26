-- Table: places
-- Schema: public
-- Description: Stores geographic locations with trait-based descriptions
-- Table Definition
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
