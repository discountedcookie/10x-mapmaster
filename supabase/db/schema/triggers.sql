-- ============================================================================
-- Database Triggers
-- ============================================================================
-- Description: Trigger definitions (CREATE TRIGGER statements)
-- Dependencies: Trigger functions must be defined first (in functions/)
-- ============================================================================
-- ============================================================================
-- game_sessions triggers
-- ============================================================================
DROP TRIGGER if EXISTS "enrich_place_on_session_complete_trigger" ON "public"."game_sessions";


CREATE TRIGGER "enrich_place_on_session_complete_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW
EXECUTE function "game_logic"."enrich_place_on_session_complete" ();


comment ON trigger "enrich_place_on_session_complete_trigger" ON "public"."game_sessions" IS 'Triggers place enrichment when a session completes successfully (was_correct = TRUE).';


DROP TRIGGER if EXISTS "on_session_approval_regenerate_traits_trigger" ON "public"."game_sessions";


CREATE TRIGGER "on_session_approval_regenerate_traits_trigger"
AFTER
UPDATE ON "public"."game_sessions" FOR each ROW WHEN (
  old.pending_review = TRUE
  AND new.pending_review = FALSE
)
EXECUTE function "game_logic"."on_session_approval_regenerate_traits" ();


comment ON trigger "on_session_approval_regenerate_traits_trigger" ON "public"."game_sessions" IS 'Triggers trait regeneration when a session is approved (pending_review: TRUE → FALSE).';
