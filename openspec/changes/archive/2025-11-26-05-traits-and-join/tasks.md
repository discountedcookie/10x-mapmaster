# Tasks: Add Traits and Join

- [x] Create traits table: id text PK, clause text NOT NULL, embedding_id uuid NULL, created_at
- [x] FKs: embedding_id → embeddings (SET NULL); index on embedding_id
- [x] Create place_traits join: place_id uuid, trait_id text, created_at; PK (place_id, trait_id)
- [x] FKs: place_id → places (CASCADE), trait_id → traits (CASCADE); index on trait_id
- [x] RLS: traits and place_traits readable by all; write restricted to service_role
- [x] Validate `openspec validate 05-traits-and-join --strict`
