-- Function: maintenance_cleanup
-- Category: maintenance
-- Deletes expired sessions and prunes question stats
CREATE OR REPLACE FUNCTION "public"."maintenance_cleanup" () returns "void" language "plpgsql" security definer AS $$
BEGIN
  -- Delete expired sessions (no activity in 24 hours)
  DELETE FROM game_sessions gs
  WHERE COALESCE(
    (SELECT MAX(created_at) FROM game_answers WHERE session_id = gs.id),
    gs.created_at
  ) < NOW() - INTERVAL '24 hours';

  -- Prune question_stats beyond cap of 450
  -- Keep top 450 by effectiveness_score DESC, times_asked ASC, created_at ASC
  WITH ranked AS (
    SELECT id
    FROM question_stats
    ORDER BY effectiveness_score DESC, times_asked ASC, created_at ASC
    OFFSET 450
  )
  DELETE FROM question_stats
  WHERE id IN (SELECT id FROM ranked);
END;
$$;


ALTER FUNCTION "public"."maintenance_cleanup" () owner TO "postgres";


comment ON function "public"."maintenance_cleanup" () IS 'Daily maintenance function that deletes expired sessions (24+ hours old)
and prunes question_stats to keep only the top 450 most effective ones.';
