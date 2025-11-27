-- Table: traits
-- Schema: public
-- Description: Canonical trait definitions used to describe and filter places
-- Spec: Each trait has id, clause (text), and embedding_id
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."traits" (
  "id" TEXT NOT NULL,
  "clause" TEXT NOT NULL,
  "embedding_id" UUID,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."traits" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."traits"
ADD CONSTRAINT "traits_pkey" PRIMARY KEY ("id");


-- Foreign Key
ALTER TABLE ONLY "public"."traits"
ADD CONSTRAINT "traits_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_traits_embedding_id" ON "public"."traits" ("embedding_id");


-- RLS Policies
ALTER TABLE "public"."traits" enable ROW level security;


DROP POLICY if EXISTS "Traits viewable by everyone" ON "public"."traits";


DROP POLICY if EXISTS "Service role can manage traits" ON "public"."traits";


CREATE POLICY "Traits viewable by everyone" ON "public"."traits" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage traits" ON "public"."traits" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."traits" IS 'Canonical trait vocabulary per spec. Each trait has id, clause (text), and embedding_id for semantic similarity calculations.';
