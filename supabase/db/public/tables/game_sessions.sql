-- Table: game_sessions
-- Schema: public
-- Description: Tracks active and completed game sessions with trait-based state
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."game_sessions" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid",
  "place_id" "uuid",
  "was_correct" BOOLEAN,
  "description" "text" NOT NULL CHECK (
    length(trim("description")) > 0
    AND length("description") <= 500
  ),
  "description_language_code" "text" DEFAULT 'en'::"text" NOT NULL,
  "affirmed_trait_ids" TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
  "denied_trait_ids" TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
  "description_embedding_id" UUID,
  "affirmed_trait_embedding_id" UUID,
  "denied_trait_embedding_id" UUID,
  "pending_review" BOOLEAN DEFAULT FALSE NOT NULL,
  "submitted_place_name" "text",
  "submitted_lat" DOUBLE PRECISION,
  "submitted_lng" DOUBLE PRECISION,
  "submitted_nominatim_id" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "next_turn" "jsonb"
);


ALTER TABLE "public"."game_sessions" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id");


-- Foreign Keys
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_description_embedding_id_fkey" FOREIGN key ("description_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_affirmed_trait_embedding_id_fkey" FOREIGN key ("affirmed_trait_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_denied_trait_embedding_id_fkey" FOREIGN key ("denied_trait_embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_game_sessions_user_id" ON "public"."game_sessions" ("user_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_place_id" ON "public"."game_sessions" ("place_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_created_at" ON "public"."game_sessions" ("created_at");


-- RLS Policies
ALTER TABLE "public"."game_sessions" enable ROW level security;


ALTER TABLE "public"."game_sessions" force ROW level security;


DROP POLICY if EXISTS "Users can view their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can insert their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can update their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can delete their own game sessions" ON "public"."game_sessions";


CREATE POLICY "Users can view their own game sessions" ON "public"."game_sessions" FOR
SELECT
  USING (
    ("auth"."uid" () = "user_id")
    OR (
      ("auth"."uid" () IS NULL)
      AND ("user_id" IS NULL)
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can insert their own game sessions" ON "public"."game_sessions" FOR insert
WITH
  CHECK (
    (
      ("auth"."uid" () IS NOT NULL)
      AND ("auth"."uid" () = "user_id")
    )
    OR (
      ("auth"."uid" () IS NULL)
      AND ("user_id" IS NULL)
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can update their own game sessions" ON "public"."game_sessions"
FOR UPDATE
  USING (
    ("auth"."uid" () = "user_id")
    OR (
      ("auth"."uid" () IS NULL)
      AND ("user_id" IS NULL)
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can delete their own game sessions" ON "public"."game_sessions" FOR delete USING (
  ("auth"."uid" () = "user_id")
  OR (
    ("auth"."uid" () IS NULL)
    AND ("user_id" IS NULL)
  )
  OR ("auth"."role" () = 'service_role'::"text")
);


-- Comments
comment ON COLUMN "public"."game_sessions"."next_turn" IS 'Cached next turn for the game session. Stores one of:
- {"action": "question", "question_id": "uuid", "question_text": "...", "candidates": [...]}
- {"action": "guess", "place_id": "uuid", "place_name": "...", "candidates": [...]}
- {"action": "give_up", "reason": "no_candidates"}
- NULL (session won/lost - check was_correct)';
