# Tasks: Add Game Sessions

- [x] Create game_sessions table: id uuid PK, user_id uuid NULL, description text NOT NULL (<=200 chars), language_code text, embedding_id uuid, next_turn jsonb, status enum, pending_review boolean NOT NULL default false, was_correct boolean, place_id uuid, created_at/updated_at
- [x] Constraints: CHECK length on description; status enum; NOT NULL where required
- [x] FKs: embedding_id → embeddings (SET NULL), place_id → places (SET NULL)
- [x] Indexes: user_id, status, place_id, created_at
- [x] RLS policies for user ownership
