-- Function: enqueue_trait_extraction
-- Category: utilities
-- Purpose: Enqueue a trait extraction job via pgmq + pg_net fire-and-forget
CREATE OR REPLACE FUNCTION "game_logic"."enqueue_trait_extraction" (
  p_place_id UUID
) returns void language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions,
  pgmq AS $$
DECLARE
  v_url TEXT;
  v_auth_token TEXT;
  v_headers JSONB;
  v_body JSONB;
  v_message_id BIGINT;
BEGIN
  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================
  IF p_place_id IS NULL THEN
    RAISE EXCEPTION 'Place ID cannot be null';
  END IF;

  -- ============================================================================
  -- ENQUEUE TO PGMQ (for durability)
  -- ============================================================================
  -- Message stays in queue until explicitly deleted after successful processing
  SELECT pgmq.send(
    'trait_extraction',
    jsonb_build_object(
      'place_id', p_place_id,
      'enqueued_at', now()
    )
  ) INTO v_message_id;

  -- ============================================================================
  -- FIRE PG_NET REQUEST (fire-and-forget for immediate processing)
  -- ============================================================================
  -- Build Edge Function URL
  v_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    game_logic.get_config_text('runtime.supabase_url')
  );
  
  IF v_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url. Trait extraction will be skipped.';
  END IF;
  
  v_url := v_url || '/functions/v1/process-trait-extraction';
  
  -- Get service role key for authentication
  v_auth_token := COALESCE(
    NULLIF(current_setting('app.service_role_key', true), ''),
    game_logic.get_config_text('runtime.supabase_service_role_key')
  );
  
  IF v_auth_token IS NULL OR v_auth_token = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.service_role_key or runtime.supabase_service_role_key. Trait extraction will be skipped.';
  END IF;
  
  -- Build request headers
  v_headers := jsonb_build_object(
    'Authorization', 'Bearer ' || v_auth_token,
    'Content-Type', 'application/json'
  );
  
  -- Build request body for generic async RPC invoker
  v_body := jsonb_build_object(
    'function_name', 'update_place_traits',
    'params', jsonb_build_object('p_place_id', p_place_id)
  );
  
  -- Fire HTTP request (fire-and-forget, no response collection)
  -- Signature: net.http_post(url, body, params, headers, timeout_milliseconds)
  -- Using 30s timeout to allow for Nominatim + LLM + embeddings calls
  PERFORM net.http_post(
    v_url,           -- url
    v_body,          -- body (jsonb)
    '{}'::jsonb,     -- params (empty)
    v_headers,       -- headers
    30000            -- timeout_milliseconds (30 seconds)
  );

EXCEPTION
  WHEN others THEN
    -- Log error but don't fail - async processing is best-effort
    RAISE EXCEPTION 'enqueue_trait_extraction failed for place %: %', p_place_id, SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."enqueue_trait_extraction" (UUID) owner TO "postgres";


comment ON function "game_logic"."enqueue_trait_extraction" (UUID) IS 'Enqueue a trait extraction job for async processing.

Two-phase async pattern:
1. pgmq.send() - Durable queue for guaranteed delivery
2. pg_net.http_post() - Fire-and-forget for immediate processing

The pgmq message provides durability - if the edge function fails,
pg_cron backup processor will pick up orphaned messages.

Parameters:
- p_place_id: UUID of place to extract traits for

Returns immediately - trait extraction happens asynchronously.';
