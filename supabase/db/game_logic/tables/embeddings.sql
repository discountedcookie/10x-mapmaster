-- Table: embeddings
-- Schema: game_logic
-- Description: Stores text embeddings separately from entities for efficient querying
-- Spec: 384d vector per spec/overview.md and openspec/specs/database/spec.md
-- Table Definition
CREATE TABLE IF NOT EXISTS "game_logic"."embeddings" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "source_text" "text" NOT NULL,
  "embedding" "extensions"."vector" (384) NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "game_logic"."embeddings" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "game_logic"."embeddings"
ADD CONSTRAINT "embeddings_pkey" PRIMARY KEY ("id");


-- Indexes
-- HNSW index for fast approximate nearest neighbor search using cosine distance
-- Uses vector_cosine_ops to match the <=> cosine distance operator used in queries
CREATE INDEX if NOT EXISTS "idx_embeddings_hnsw" ON "game_logic"."embeddings" USING hnsw ("embedding" extensions.vector_cosine_ops);


-- Unique constraint on source_text for deduplication
CREATE UNIQUE INDEX if NOT EXISTS "idx_embeddings_source_text" ON "game_logic"."embeddings" ("source_text");


-- RLS Policies
ALTER TABLE "game_logic"."embeddings" enable ROW level security;


DROP POLICY if EXISTS "Embeddings are viewable by everyone" ON "game_logic"."embeddings";


DROP POLICY if EXISTS "Service role can manage embeddings" ON "game_logic"."embeddings";


CREATE POLICY "Service role can manage embeddings" ON "game_logic"."embeddings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Explicitly revoke read access from non-service roles; only service_role should see embeddings
REVOKE ALL ON game_logic.embeddings
FROM
  public,
  anon,
  authenticated;


-- Comments
comment ON TABLE "game_logic"."embeddings" IS 'Stores 384d text embeddings (gte-small compatible).';
