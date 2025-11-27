-- Function: get_max_turns
-- Category: utilities
-- Purpose: Get max_turns setting from game_logic.config (DRY helper)
CREATE OR REPLACE FUNCTION "game_logic"."get_max_turns" () returns INTEGER language sql stable security definer
SET
  search_path = public,
  game_logic AS $$
  SELECT get_config_int('game.max_turns', 5);
$$;


ALTER FUNCTION "game_logic"."get_max_turns" () owner TO "postgres";


comment ON function "game_logic"."get_max_turns" () IS 'Get max_turns from game_logic.config table.
Returns 5 if setting not found.
Marked STABLE for query optimization.';
