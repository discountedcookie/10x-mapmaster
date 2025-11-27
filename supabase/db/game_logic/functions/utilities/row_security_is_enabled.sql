-- Helper: row_security_is_enabled
-- Purpose: pgTAP helper to assert RLS is enabled on a table
-- Schema: public (SECURITY DEFINER)
-- Note: Simple mirror of pg_class.relrowsecurity for the given table
CREATE OR REPLACE FUNCTION "game_logic"."row_security_is_enabled" (p_schema TEXT, p_table TEXT, p_description TEXT) returns BOOLEAN language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = p_schema
      AND c.relname = p_table
      AND c.relrowsecurity
  );
END;
$$;
