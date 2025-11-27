# Tasks: Add Game Answers

- [x] Create game_answers table: id uuid PK, session_id uuid NOT NULL, trait_id text NULL, geographic_region_id uuid NULL, place_id uuid NULL, answer answer_value NOT NULL, candidates jsonb NULL, question_text text NULL, created_at timestamptz
- [x] CHECK: num_nonnulls(trait_id, geographic_region_id, place_id) = 1
- [x] FKs: session_id → game_sessions ON DELETE CASCADE; trait_id → traits ON DELETE CASCADE; geographic_region_id → geographic_regions ON DELETE CASCADE; place_id → places ON DELETE CASCADE
- [x] Indexes: session_id; polymorphic index on (trait_id, geographic_region_id, place_id)
- [x] RLS policies for session ownership
