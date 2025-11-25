-- ============================================================================
-- Database Triggers
-- ============================================================================
-- Description: Trigger definitions that call trigger functions
-- Dependencies: Tables (02_tables.sql), Trigger Functions (supabase/db/functions/utilities/)
-- Note: Trigger functions are defined in supabase/db/functions/utilities/
-- ============================================================================
DROP TRIGGER if EXISTS "enrich_place_on_session_complete_trigger" ON "public"."game_sessions";


CREATE TRIGGER "enrich_place_on_session_complete_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW
EXECUTE function "public"."enrich_place_on_session_complete" ();


comment ON trigger "enrich_place_on_session_complete_trigger" ON "public"."game_sessions" IS 'Triggers place enrichment when a session completes successfully (was_correct = TRUE).';


-- ============================================================================
-- Function-Level Security (EXECUTE Permissions)
-- ============================================================================
-- Description: Control which functions can be called directly by users
-- vs which are internal-only (called by other functions)
-- Note: This section must come AFTER all functions are defined
-- ============================================================================
-- ============================================================================
-- generate_embedding - INTERNAL ONLY
-- ============================================================================
-- This function should ONLY be called by other database functions (start_game, etc.)
-- NOT directly from the frontend, to prevent API quota abuse.
-- Rate limiting is enforced at the entry points (start_game, etc.)
REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  public;


REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  anon;


REVOKE
EXECUTE ON function public.generate_embedding (TEXT)
FROM
  authenticated;


-- Only postgres role and service_role can execute
GRANT
EXECUTE ON function public.generate_embedding (TEXT) TO postgres;


GRANT
EXECUTE ON function public.generate_embedding (TEXT) TO service_role;
