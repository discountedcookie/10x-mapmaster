-- Function: get_max_turns
-- Category: utilities
-- Purpose: Get max_turns setting from app_settings (DRY helper)
CREATE OR REPLACE FUNCTION "public"."get_max_turns" () returns INTEGER language sql stable
SET
  search_path = public AS $$
  SELECT COALESCE((value)::INT, 5)
  FROM app_settings
  WHERE key = 'max_turns';
$$;


ALTER FUNCTION "public"."get_max_turns" () owner TO "postgres";


comment ON function "public"."get_max_turns" () IS 'Get max_turns from app_settings table.
Returns 5 if setting not found.
Marked STABLE for query optimization.';
