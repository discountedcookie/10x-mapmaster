-- Deferred RLS Policies
-- Schema: public
-- Description: RLS policies that reference tables with circular dependencies
-- These policies must be created after ALL tables exist
-- Places: Users can delete their own places (depends on game_sessions)
DROP POLICY if EXISTS "Users can delete their own places" ON "public"."places";


CREATE POLICY "Users can delete their own places" ON "public"."places" FOR delete USING (
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
);
