-- Function: http_call_edge_function
-- Category: utilities
-- Purpose: Call Supabase Edge Functions from database using pg_net extension
CREATE OR REPLACE FUNCTION "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT DEFAULT 'POST',
  p_headers JSONB DEFAULT '{}',
  p_body JSONB DEFAULT '{}'
) returns JSONB language plpgsql security definer
SET
  search_path = public, extensions, game_logic AS $$
DECLARE
  v_url TEXT;
  v_auth_token TEXT;
  v_response_body TEXT;
  v_response_status INT;
  v_result JSONB;
BEGIN
  -- Build Edge Function URL (from GUC vars or game_logic.config - NO hardcoded values)
  v_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF v_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  v_url := v_url || '/functions/v1/' || p_function_name;
  
  -- Get service role key for authentication (NO hardcoded secrets)
  v_auth_token := COALESCE(
    NULLIF(current_setting('app.service_role_key', true), ''),
    get_config_text('runtime.supabase_service_role_key')
  );
  
  IF v_auth_token IS NULL OR v_auth_token = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.service_role_key or runtime.supabase_service_role_key';
  END IF;
  
  -- Add authorization header
  p_headers := p_headers || jsonb_build_object(
    'Authorization', 'Bearer ' || v_auth_token,
    'Content-Type', 'application/json'
  );
  
  -- Make HTTP request using pg_net
  PERFORM net.http_post(
    url := v_url,
    headers := p_headers,
    body := jsonb_build_object('data', p_body)::text
  );
  
  -- Wait for response
  SELECT 
    body,
    status
  INTO v_response_body, v_response_status
  FROM net.http_collect_response(
    (SELECT id FROM net.http_request ORDER BY created_at DESC LIMIT 1)
  );
  
  -- Check for HTTP errors
  IF v_response_status < 200 OR v_response_status >= 300 THEN
    RAISE EXCEPTION 'Edge function call failed: status %, body: %', v_response_status, v_response_body;
  END IF;
  
  -- Parse and return JSON response
  BEGIN
    v_result := v_response_body::jsonb;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'Edge function returned invalid JSON: %', v_response_body;
  END;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT,
  p_headers JSONB,
  p_body JSONB
) owner TO "postgres";


comment ON function "game_logic"."http_call_edge_function" (
  p_function_name TEXT,
  p_method TEXT,
  p_headers JSONB,
  p_body JSONB
) IS 'Call Supabase Edge Functions from database using pg_net extension.

Requires pg_net extension and app settings:
- app.supabase_url: Supabase project URL
- app.service_role_key: Service role key for authentication

Parameters:
- p_function_name: Name of edge function (without path)
- p_method: HTTP method (default: POST)
- p_headers: Additional headers as JSONB
- p_body: Request body as JSONB

Returns: JSONB response from edge function

Raises exception on HTTP errors or invalid JSON response.';
