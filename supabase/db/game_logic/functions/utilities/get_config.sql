-- Function: get_config
-- Category: utilities
-- Purpose: Retrieve configuration value from game_logic.config
CREATE OR REPLACE FUNCTION "game_logic"."get_config" ("p_key" TEXT) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  RETURN v_value;
END;
$$;


-- Helper function to get numeric config value (FLOAT)
CREATE OR REPLACE FUNCTION "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT DEFAULT 0.0) returns FLOAT language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default::TEXT)::FLOAT;
END;
$$;


-- Helper function to get integer config value
CREATE OR REPLACE FUNCTION "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER DEFAULT 0) returns INTEGER language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default::TEXT)::INTEGER;
END;
$$;


-- Helper function to get text config value
CREATE OR REPLACE FUNCTION "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT DEFAULT NULL) returns TEXT language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT value INTO v_value
  FROM game_logic.config
  WHERE key = p_key
  LIMIT 1;
  
  IF v_value IS NULL THEN
    RETURN p_default;
  END IF;
  
  RETURN COALESCE(v_value#>>'{}', p_default);
END;
$$;


ALTER FUNCTION "game_logic"."get_config" ("p_key" TEXT) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER) owner TO "postgres";


ALTER FUNCTION "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT) owner TO "postgres";


comment ON function "game_logic"."get_config" ("p_key" TEXT) IS 'Retrieve configuration value from game_logic.config as JSONB.
Returns NULL if key not found.';


comment ON function "game_logic"."get_config_float" ("p_key" TEXT, "p_default" FLOAT) IS 'Retrieve configuration value as FLOAT with default.';


comment ON function "game_logic"."get_config_int" ("p_key" TEXT, "p_default" INTEGER) IS 'Retrieve configuration value as INTEGER with default.';


comment ON function "game_logic"."get_config_text" ("p_key" TEXT, "p_default" TEXT) IS 'Retrieve configuration value as TEXT with default.';
