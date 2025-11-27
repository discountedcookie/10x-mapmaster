-- Table: rate_limit_log
-- Schema: game_logic
-- Description: Tracks rate limit requests for enforcement and analytics (internal)
CREATE TABLE IF NOT EXISTS "game_logic"."rate_limit_log" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid" NOT NULL,
  "action" "text" NOT NULL,
  "ip_address" "inet",
  "user_agent" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "game_logic"."rate_limit_log" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "game_logic"."rate_limit_log"
ADD CONSTRAINT "rate_limit_log_pkey" PRIMARY KEY ("id");


-- Indexes
CREATE INDEX if NOT EXISTS "idx_rate_limit_log_user_id" ON "game_logic"."rate_limit_log" ("user_id");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_created_at" ON "game_logic"."rate_limit_log" ("created_at");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_action" ON "game_logic"."rate_limit_log" ("action");


-- RLS Policies
ALTER TABLE "game_logic"."rate_limit_log" enable ROW level security;


ALTER TABLE "game_logic"."rate_limit_log" force ROW level security;


DROP POLICY if EXISTS "Service role can manage rate limit log" ON "game_logic"."rate_limit_log";


CREATE POLICY "Service role can manage rate limit log" ON "game_logic"."rate_limit_log" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Table Grants (required before RLS policies can be evaluated)
GRANT
SELECT
,
  insert,
UPDATE,
delete ON "game_logic"."rate_limit_log" TO service_role;


GRANT
SELECT
,
  insert,
UPDATE,
delete ON "game_logic"."rate_limit_log" TO postgres;


-- Comments
comment ON TABLE "game_logic"."rate_limit_log" IS 'Internal: Tracks rate limit requests. Cleaned up by pg_cron.';


comment ON COLUMN "game_logic"."rate_limit_log"."action" IS 'Action being rate limited (e.g., start_game, play_turn)';
