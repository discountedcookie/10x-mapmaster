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
    AND length("description") <= 200
  ),
  "language_code" "text" DEFAULT 'en'::"text" NOT NULL,
  "embedding_id" UUID,
  "status" "game_session_status" DEFAULT 'active'::"game_session_status" NOT NULL,
  "pending_review" BOOLEAN DEFAULT FALSE NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  "next_turn" "jsonb"
);


ALTER TABLE "public"."game_sessions" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id");


-- Foreign Keys
ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE SET NULL;


ALTER TABLE ONLY "public"."game_sessions"
ADD CONSTRAINT "game_sessions_embedding_id_fkey" FOREIGN key ("embedding_id") REFERENCES "public"."embeddings" ("id") ON DELETE SET NULL;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_game_sessions_user_id" ON "public"."game_sessions" ("user_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_place_id" ON "public"."game_sessions" ("place_id");


CREATE INDEX if NOT EXISTS "idx_game_sessions_created_at" ON "public"."game_sessions" ("created_at");


CREATE INDEX if NOT EXISTS "idx_game_sessions_status" ON "public"."game_sessions" ("status");


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


-- Note: Triggers defined in schema/triggers.sql (loaded after functions)
