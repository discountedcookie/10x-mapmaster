-- Function: maintenance_cleanup
-- Category: maintenance
-- Deletes expired sessions, prunes question stats, and cleans up rate limit logs
CREATE OR REPLACE FUNCTION "game_logic"."maintenance_cleanup" () returns "void" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
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
    FROM game_logic.question_stats
    ORDER BY effectiveness_score DESC, times_asked ASC, created_at ASC
    OFFSET 450
  )
  DELETE FROM game_logic.question_stats
  WHERE id IN (SELECT id FROM ranked);

  -- Clean up old rate_limit_log entries (older than 1 hour)
  -- Rate limit entries are only needed for enforcement within the time window
  DELETE FROM game_logic.rate_limit_log
  WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$;


ALTER FUNCTION "game_logic"."maintenance_cleanup" () owner TO "postgres";


comment ON function "game_logic"."maintenance_cleanup" () IS 'Daily maintenance function that deletes expired sessions (24+ hours old)
and prunes question_stats to keep only the top 450 most effective ones.';
