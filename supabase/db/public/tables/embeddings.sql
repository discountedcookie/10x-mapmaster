-- Table: embeddings
-- Schema: public
-- Description: Stores text embeddings separately from entities for efficient querying
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."embeddings" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "text" "text" NOT NULL,
  "text_hash" "text" NOT NULL,
  "embedding" "public"."vector" (1024) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."embeddings" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");


-- Unique Constraint
ALTER TABLE ONLY "public"."embeddings"
ADD CONSTRAINT "embeddings_text_hash_key" UNIQUE ("text_hash");


-- Indexes
CREATE INDEX if NOT EXISTS "idx_embeddings_text_hash" ON "public"."embeddings" ("text_hash");


-- HNSW index for fast approximate nearest neighbor search
CREATE INDEX if NOT EXISTS "idx_embeddings_hnsw" ON "public"."embeddings" USING hnsw ("embedding" vector_cosine_ops);


-- RLS Policies
ALTER TABLE "public"."embeddings" enable ROW level security;


DROP POLICY if EXISTS "Embeddings are viewable by everyone" ON "public"."embeddings";


DROP POLICY if EXISTS "Service role can manage embeddings" ON "public"."embeddings";


CREATE POLICY "Embeddings are viewable by everyone" ON "public"."embeddings" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage embeddings" ON "public"."embeddings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."embeddings" IS 'Stores text embeddings separately from entities. Text is hashed for deduplication and fast lookup.';
