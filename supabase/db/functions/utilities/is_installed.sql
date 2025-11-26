-- Helper: is_installed
-- Purpose: Test helper to check extension presence (pgTAP compatible signature)
-- Note: Ignores the description argument; returns true if extension exists.
CREATE OR REPLACE FUNCTION is_installed (p_extname TEXT, p_description TEXT) returns BOOLEAN language sql stable AS $$
  SELECT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = p_extname
  );
$$;
