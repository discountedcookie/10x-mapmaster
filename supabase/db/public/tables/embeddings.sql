-- Table: embeddings
-- Schema: public
-- Description: Stores text embeddings separately from entities for efficient querying
-- Spec: 384d vector per spec/overview.md and openspec/specs/database/spec.md
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."embeddings" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "source_text" "text" NOT NULL,
  "embedding" "extensions"."vector" (384) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."embeddings" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");


-- Indexes
-- HNSW index for fast approximate nearest neighbor search
CREATE INDEX if NOT EXISTS "idx_embeddings_hnsw" ON "public"."embeddings" USING hnsw ("embedding" extensions.vector_ip_ops);


-- Unique constraint on source_text for deduplication
CREATE UNIQUE INDEX if NOT EXISTS "idx_embeddings_source_text" ON "public"."embeddings" ("source_text");


-- RLS Policies
ALTER TABLE "public"."embeddings" enable ROW level security;


DROP POLICY if EXISTS "Embeddings are viewable by everyone" ON "public"."embeddings";


DROP POLICY if EXISTS "Service role can manage embeddings" ON "public"."embeddings";


CREATE POLICY "Service role can manage embeddings" ON "public"."embeddings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Explicitly revoke read access from non-service roles; only service_role should see embeddings
REVOKE ALL ON public.embeddings
FROM
  public,
  anon,
  authenticated;


-- Comments
comment ON TABLE "public"."embeddings" IS 'Stores 384d text embeddings (gte-small compatible).';
