-- Table: app_settings
-- Schema: public
-- Description: Stores application configuration including LLM prompts
-- Table Definition
CREATE TABLE IF NOT EXISTS "public"."app_settings" (
  "key" "text" NOT NULL,
  "value" "text" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "public"."app_settings" owner TO "postgres";


-- RLS Policies
ALTER TABLE "public"."app_settings" enable ROW level security;


DROP POLICY if EXISTS "App settings are readable by everyone" ON "public"."app_settings";


DROP POLICY if EXISTS "Service role can manage app settings" ON "public"."app_settings";


CREATE POLICY "App settings are readable by everyone" ON "public"."app_settings" FOR
SELECT
  USING (TRUE);


CREATE POLICY "Service role can manage app settings" ON "public"."app_settings" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Comments
comment ON TABLE "public"."app_settings" IS 'Application configuration settings including LLM system prompts';


comment ON COLUMN "public"."app_settings"."key" IS 'Configuration key (e.g., question_generation_system_prompt)';


comment ON COLUMN "public"."app_settings"."value" IS 'Configuration value (e.g., system prompt text)';


comment ON COLUMN "public"."app_settings"."description" IS 'Human-readable description of the setting';
