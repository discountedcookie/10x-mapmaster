# Tasks: Add Places and Geometry

- [x] Create places table: id uuid PK, name text NOT NULL, osm_id text NOT NULL UNIQUE, lat/lng, geom geometry, embedding_id uuid, pending_review boolean NOT NULL default false, times_encountered int default 0, created_at/updated_at
- [x] FKs: embedding_id → embeddings (SET NULL)
- [x] Indexes: GIST on geom, index on embedding_id, index on name (text), unique osm_id
- [x] RLS: read-open; write restricted to service_role
- [x] Comments and constraints
