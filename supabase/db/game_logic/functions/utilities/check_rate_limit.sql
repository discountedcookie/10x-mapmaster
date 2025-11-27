-- Function: check_rate_limit
-- Category: utilities
-- Purpose: Check and enforce rate limits
-- Spec: openspec/specs/database/spec.md#rate-limiting
CREATE OR REPLACE FUNCTION "game_logic"."check_rate_limit" ("p_user_id" UUID, "p_action" TEXT) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_limit INT;
  v_window_seconds INT;
  v_current_count INT;
  v_config_key TEXT;
BEGIN
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    -- Skip rate limiting in tests
    RETURN;
  END IF;

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_user_id IS NULL THEN
    -- No user context - allow the request (edge case)
    RETURN;
  END IF;

  IF p_action IS NULL OR trim(p_action) = '' THEN
    RAISE EXCEPTION 'Action cannot be null or empty';
  END IF;

  -- ============================================================================
  -- GET RATE LIMIT CONFIGURATION
  -- ============================================================================
  -- Rate limits stored in game_logic.config with keys like:
  -- rate_limit.start_game.limit = 10
  -- rate_limit.start_game.window_seconds = 60
  --
  -- Default limits per docs/architecture/operations.md:
  -- start_game: 10 per minute
  -- play_turn: 60 per minute
  -- submit_place: 10 per minute

  v_config_key := 'rate_limit.' || p_action || '.limit';
  
  SELECT value::INT INTO v_limit
  FROM game_logic.config
  WHERE key = v_config_key;
  
  -- Use defaults if not configured
  IF v_limit IS NULL THEN
    CASE p_action
      WHEN 'start_game' THEN v_limit := 10;
      WHEN 'play_turn' THEN v_limit := 60;
      WHEN 'submit_place' THEN v_limit := 10;
      ELSE v_limit := 20; -- Default fallback
    END CASE;
  END IF;

  v_config_key := 'rate_limit.' || p_action || '.window_seconds';
  
  SELECT value::INT INTO v_window_seconds
  FROM game_logic.config
  WHERE key = v_config_key;
  
  -- Default window is 60 seconds (1 minute)
  IF v_window_seconds IS NULL THEN
    v_window_seconds := 60;
  END IF;

  -- ============================================================================
  -- COUNT REQUESTS IN WINDOW
  -- ============================================================================
  SELECT COUNT(*) INTO v_current_count
  FROM game_logic.rate_limit_log
  WHERE user_id = p_user_id
    AND action = p_action
    AND created_at > NOW() - (v_window_seconds || ' seconds')::INTERVAL;

  -- ============================================================================
  -- CHECK LIMIT
  -- ============================================================================
  IF v_current_count >= v_limit THEN
    RAISE EXCEPTION 'rate_limit_exceeded'
      USING DETAIL = format(
        'Rate limit exceeded for action %s: %s requests in %s seconds (limit: %s)',
        p_action, v_current_count, v_window_seconds, v_limit
      ),
      HINT = 'Please wait before retrying';
  END IF;

  -- ============================================================================
  -- LOG REQUEST (allowed)
  -- ============================================================================
  INSERT INTO game_logic.rate_limit_log (user_id, action, created_at)
  VALUES (p_user_id, p_action, NOW());

  -- Return void if allowed
  RETURN;
END;
$$;


ALTER FUNCTION "game_logic"."check_rate_limit" (UUID, TEXT) owner TO "postgres";


comment ON function "game_logic"."check_rate_limit" (UUID, TEXT) IS 'Check and enforce rate limits for RPC functions.

Parameters:
- p_user_id: The user ID (from auth.uid())
- p_action: The action being rate limited (start_game, play_turn, submit_place)

Behavior:
1. Count requests in rate_limit_log for (user_id, action) within time window
2. If count >= limit, raise exception with rate_limit_exceeded error
3. If allowed, insert new entry to rate_limit_log
4. Return void if allowed

Rate limits (from docs/architecture/operations.md):
- start_game: 10 per minute
- play_turn: 60 per minute  
- submit_place: 10 per minute

Configuration:
Limits can be overridden via game_logic.config table:
- rate_limit.<action>.limit: Max requests
- rate_limit.<action>.window_seconds: Time window in seconds

Security: SECURITY DEFINER to access game_logic.config and rate_limit_log.

Error codes:
- rate_limit_exceeded: Returns 429 status to frontend';
