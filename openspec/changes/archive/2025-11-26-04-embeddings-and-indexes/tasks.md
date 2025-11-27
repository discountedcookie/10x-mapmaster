# Tasks: Add Embeddings and Indexes

- [x] Create embeddings table: id uuid PK, source_text text NOT NULL, embedding vector(384) NOT NULL, created_at
- [x] Constraints: unique on source_text; NOT NULL checks
- [x] Index: HNSW on embedding using vector_ip_ops
- [x] Comments
- [x] RLS: SELECT open, write restricted to service_role
- [x] Validate `openspec validate 04-embeddings-and-indexes --strict`
