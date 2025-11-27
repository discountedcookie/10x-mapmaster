-- Table: config
-- Schema: public
-- Description: Client-visible configuration settings
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."config" (
  "key" "text" NOT NULL,
  "value" "jsonb" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "public"."config" owner TO "postgres";


-- RLS Policies
ALTER TABLE "public"."config" enable ROW level security;


DROP POLICY if EXISTS "Public config is readable by everyone" ON "public"."config";


DROP POLICY if EXISTS "Service role can manage public config" ON "public"."config";


CREATE POLICY "Public config is readable by everyone" ON "public"."config" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage public config" ON "public"."config" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."config" IS 'Client-visible configuration settings (e.g., game.max_turns)';


comment ON COLUMN "public"."config"."key" IS 'Configuration key (e.g., game.max_turns)';


comment ON COLUMN "public"."config"."value" IS 'Configuration value as JSON';


comment ON COLUMN "public"."config"."description" IS 'Human-readable description of the setting';
