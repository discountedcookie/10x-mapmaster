-- Table: rate_limit_log
-- Schema: public
-- Description: Tracks rate limit requests for enforcement and analytics
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."rate_limit_log" (
  "id" "uuid" DEFAULT "gen_random_uuid" () NOT NULL,
  "user_id" "uuid" NOT NULL,
  "action" "text" NOT NULL,
  "ip_address" "inet",
  "user_agent" "text",
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL
);


ALTER TABLE "public"."rate_limit_log" owner TO "postgres";


-- Primary Key
ALTER TABLE ONLY "public"."rate_limit_log"
ADD CONSTRAINT "rate_limit_log_pkey" PRIMARY KEY ("id");


-- Indexes
CREATE INDEX if NOT EXISTS "idx_rate_limit_log_user_id" ON "public"."rate_limit_log" ("user_id");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_created_at" ON "public"."rate_limit_log" ("created_at");


CREATE INDEX if NOT EXISTS "idx_rate_limit_log_action" ON "public"."rate_limit_log" ("action");


-- RLS Policies
ALTER TABLE "public"."rate_limit_log" enable ROW level security;


ALTER TABLE "public"."rate_limit_log" force ROW level security;


DROP POLICY if EXISTS "Service role can manage rate limit log" ON "public"."rate_limit_log";


CREATE POLICY "Service role can manage rate limit log" ON "public"."rate_limit_log" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."rate_limit_log" IS 'Tracks rate limit requests for enforcement and analytics. Entries older than rate limit window are cleaned up by pg_cron.';


comment ON COLUMN "public"."rate_limit_log"."action" IS 'Action being rate limited (e.g., start_game, play_turn, submit_place)';
