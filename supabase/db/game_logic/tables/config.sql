-- Table: config
-- Schema: game_logic
-- Description: Server-only configuration settings for game logic
-- Table Definition
CREATE TABLE IF NOT EXISTS "game_logic"."config" (
  "key" "text" NOT NULL,
  "value" "jsonb" NOT NULL,
  "description" "text",
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT "now" () NOT NULL,
  PRIMARY KEY ("key")
);


ALTER TABLE "game_logic"."config" owner TO "postgres";


-- RLS Policies
ALTER TABLE "game_logic"."config" enable ROW level security;


ALTER TABLE "game_logic"."config" force ROW level security;


DROP POLICY if EXISTS "Service role can manage game_logic config" ON "game_logic"."config";


CREATE POLICY "Service role can manage game_logic config" ON "game_logic"."config" FOR ALL USING (("auth"."role" () = 'service_role'::"text"))
WITH
  CHECK (("auth"."role" () = 'service_role'::"text"));


-- Grant access to service role
GRANT usage ON schema game_logic TO service_role;


GRANT
SELECT
,
  insert,
UPDATE,
delete ON TABLE game_logic.config TO service_role;


-- Comments
comment ON TABLE "game_logic"."config" IS 'Server-only configuration settings for game logic (e.g., scoring.temperature, confidence thresholds)';


comment ON COLUMN "game_logic"."config"."key" IS 'Configuration key (e.g., scoring.temperature)';


comment ON COLUMN "game_logic"."config"."value" IS 'Configuration value as JSON';


comment ON COLUMN "game_logic"."config"."description" IS 'Human-readable description of the setting';
