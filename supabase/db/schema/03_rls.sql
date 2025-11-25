-- ============================================================================
-- Row Level Security (RLS) Policies
-- ============================================================================
-- Description: RLS policies for all tables to enforce data access control
-- Dependencies: Tables (02_tables.sql)
-- ============================================================================
-- ============================================================================
-- places table RLS
-- ============================================================================
ALTER TABLE "public"."places" enable ROW level security;


DROP POLICY if EXISTS "Places are viewable by everyone" ON "public"."places";


DROP POLICY if EXISTS "Service role can insert places" ON "public"."places";


DROP POLICY if EXISTS "Service role can update places" ON "public"."places";


DROP POLICY if EXISTS "Users can delete their own places" ON "public"."places";


CREATE POLICY "Places are viewable by everyone" ON "public"."places" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can insert places" ON "public"."places" FOR insert
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


CREATE POLICY "Service role can update places" ON "public"."places"
FOR UPDATE
  USING (("auth"."role" () = 'service_role'::"text"));


CREATE POLICY "Users can delete their own places" ON "public"."places" FOR delete USING (
  (
    (
      "id" IN (
        SELECT
          "game_sessions"."place_id"
        FROM
          "public"."game_sessions"
        WHERE
          ("game_sessions"."user_id" = "auth"."uid" ())
      )
    )
    OR ("auth"."role" () = 'service_role'::"text")
  )
);


-- ============================================================================
-- place_traits table RLS
-- ============================================================================
ALTER TABLE "public"."place_traits" enable ROW level security;


DROP POLICY if EXISTS "Place traits viewable by everyone" ON "public"."place_traits";


DROP POLICY if EXISTS "Service role can manage place traits" ON "public"."place_traits";


CREATE POLICY "Place traits viewable by everyone" ON "public"."place_traits" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place traits" ON "public"."place_traits" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- place_trait_links table RLS
-- ============================================================================
ALTER TABLE "public"."place_trait_links" enable ROW level security;


DROP POLICY if EXISTS "Place trait links viewable by everyone" ON "public"."place_trait_links";


DROP POLICY if EXISTS "Service role can manage place trait links" ON "public"."place_trait_links";


CREATE POLICY "Place trait links viewable by everyone" ON "public"."place_trait_links" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage place trait links" ON "public"."place_trait_links" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- question_stats table RLS
-- ============================================================================
ALTER TABLE "public"."question_stats" enable ROW level security;


DROP POLICY if EXISTS "Question stats viewable by everyone" ON "public"."question_stats";


DROP POLICY if EXISTS "Service role can manage question stats" ON "public"."question_stats";


CREATE POLICY "Question stats viewable by everyone" ON "public"."question_stats" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage question stats" ON "public"."question_stats" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- ============================================================================
-- game_answers table RLS
-- ============================================================================
ALTER TABLE "public"."game_answers" enable ROW level security;


DROP POLICY if EXISTS "Users can insert answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can update answers for their sessions" ON "public"."game_answers";


DROP POLICY if EXISTS "Users can view answers for their sessions" ON "public"."game_answers";


CREATE POLICY "Users can insert answers for their sessions" ON "public"."game_answers" FOR insert
WITH
  CHECK (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


CREATE POLICY "Users can update answers for their sessions" ON "public"."game_answers"
FOR UPDATE
  USING (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


CREATE POLICY "Users can view answers for their sessions" ON "public"."game_answers" FOR
SELECT
  USING (
    (
      (
        (
          "session_id" IN (
            SELECT
              "game_sessions"."id"
            FROM
              "public"."game_sessions"
            WHERE
              (
                ("game_sessions"."user_id" = "auth"."uid" ())
                OR (
                  ("game_sessions"."user_id" IS NULL)
                  AND ("auth"."uid" () IS NULL)
                )
              )
          )
        )
        OR ("auth"."role" () = 'service_role'::"text")
      )
    )
  );


-- ============================================================================
-- game_sessions table RLS
-- ============================================================================
ALTER TABLE "public"."game_sessions" enable ROW level security;


DROP POLICY if EXISTS "Users can view their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can insert their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can update their own game sessions" ON "public"."game_sessions";


DROP POLICY if EXISTS "Users can delete their own game sessions" ON "public"."game_sessions";


CREATE POLICY "Users can view their own game sessions" ON "public"."game_sessions" FOR
SELECT
  USING (
    (
      ("auth"."uid" () = "user_id")
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can insert their own game sessions" ON "public"."game_sessions" FOR insert
WITH
  CHECK (
    (
      (
        ("auth"."uid" () IS NOT NULL)
        AND ("auth"."uid" () = "user_id")
      )
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can update their own game sessions" ON "public"."game_sessions"
FOR UPDATE
  USING (
    (
      ("auth"."uid" () = "user_id")
      OR (
        ("auth"."uid" () IS NULL)
        AND ("user_id" IS NULL)
      )
      OR ("auth"."role" () = 'service_role'::"text")
    )
  );


CREATE POLICY "Users can delete their own game sessions" ON "public"."game_sessions" FOR delete USING (
  (
    ("auth"."uid" () = "user_id")
    OR (
      ("auth"."uid" () IS NULL)
      AND ("user_id" IS NULL)
    )
    OR ("auth"."role" () = 'service_role'::"text")
  )
);


-- ============================================================================
-- app_settings table RLS
-- ============================================================================
ALTER TABLE "public"."app_settings" enable ROW level security;


DROP POLICY if EXISTS "App settings are readable by everyone" ON "public"."app_settings";


DROP POLICY if EXISTS "Service role can manage app settings" ON "public"."app_settings";


CREATE POLICY "App settings are readable by everyone" ON "public"."app_settings" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage app settings" ON "public"."app_settings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));
