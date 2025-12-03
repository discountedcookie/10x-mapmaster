-- Table: game_answers
-- Schema: public
-- Description: Records each answer (question response or wrong guess) during a game session
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."game_answers" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "session_id" "uuid" NOT NULL,
  "trait_id" UUID,
  "geographic_region_id" "uuid",
  "answer" answer_value NOT NULL,
  "place_id" "uuid",
  "candidates" "jsonb",
  "question_text" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."game_answers" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_pkey" PRIMARY KEY ("id");


-- Polymorphic constraint: exactly one of trait_id, geographic_region_id, place_id must be set
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_polymorphic_check" CHECK (
  num_nonnulls (trait_id, geographic_region_id, place_id) = 1
);


-- Foreign Keys
ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_session_id_fkey" FOREIGN key ("session_id") REFERENCES "public"."game_sessions" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_place_id_fkey" FOREIGN key ("place_id") REFERENCES "public"."places" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_trait_id_fkey" FOREIGN key ("trait_id") REFERENCES "public"."traits" ("id") ON DELETE CASCADE;


ALTER TABLE ONLY "public"."game_answers"
ADD CONSTRAINT "game_answers_geographic_region_id_fkey" FOREIGN key ("geographic_region_id") REFERENCES "game_logic"."geographic_regions" ("id") ON DELETE CASCADE;


-- Indexes
CREATE INDEX if NOT EXISTS "idx_game_answers_session_id" ON "public"."game_answers" ("session_id");


CREATE INDEX if NOT EXISTS "idx_game_answers_polymorphic" ON "public"."game_answers" (trait_id, geographic_region_id, place_id);


-- RLS Policies
ALTER TABLE "public"."game_answers" enable ROW level security;


ALTER TABLE "public"."game_answers" force ROW level security;


DROP POLICY if EXISTS "Users can insert answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can update answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can view answers for their sessions" ON "public"."game_answers";


CREATE POLICY "Users can view answers for their sessions" ON "public"."game_answers" FOR
SELECT
  USING (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can insert answers for their sessions" ON "public"."game_answers" FOR insert
WITH
  CHECK (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


CREATE POLICY "Users can update answers for their sessions" ON "public"."game_answers"
FOR UPDATE
  USING (
    (
      "session_id" IN (
        SELECT
          "game_sessions"."id"
        FROM
          "public"."game_sessions"
        WHERE
          (("game_sessions"."user_id" = "auth"."uid" ()))
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  );


-- Comments
comment ON TABLE "public"."game_answers" IS 'Records player answers. Questions are generated from trait_id or geographic_region_id, not stored.';
