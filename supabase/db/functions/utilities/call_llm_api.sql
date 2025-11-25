-- Function: call_llm_api
-- Category: utilities
-- Purpose: Call LLM via edge function with a prompt
-- Returns: LLM response text
CREATE OR REPLACE FUNCTION "public"."call_llm_api" ("p_prompt" "text", "p_format" "text" DEFAULT NULL) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  extensions AS $$
DECLARE
  v_response extensions.http_response;
  v_edge_function_url TEXT;
  v_anon_key TEXT;
  v_llm_response TEXT;
  v_request_body JSONB;
  v_llm_model TEXT;
  v_llm_options JSONB;
  v_llm_temperature FLOAT;
  v_llm_num_predict INT;
  v_llm_top_p FLOAT;
  v_llm_stop JSONB;
BEGIN
  -- Increase statement timeout for slower LLM responses (default 5s is too short)
  PERFORM set_config('statement_timeout', '15s', true);
  -- Increase HTTP timeout (default 5s) so curl waits for Ollama
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '15000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '5000');
  -- ============================================================================
  -- CONFIGURATION
  -- ============================================================================
  v_edge_function_url := COALESCE(
    current_setting('app.supabase_url', true),
    'http://host.docker.internal:54321'
  ) || '/functions/v1/call-llm';

  v_anon_key := COALESCE(
    current_setting('app.supabase_anon_key', true),
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
  );

  -- ============================================================================
  -- FETCH LLM SETTINGS FROM app_settings (FAIL if missing)
  -- ============================================================================
  SELECT value INTO STRICT v_llm_model FROM app_settings WHERE key = 'llm_model';
  SELECT value::FLOAT INTO STRICT v_llm_temperature FROM app_settings WHERE key = 'llm_temperature';
  SELECT value::INT INTO STRICT v_llm_num_predict FROM app_settings WHERE key = 'llm_num_predict';
  SELECT value::FLOAT INTO STRICT v_llm_top_p FROM app_settings WHERE key = 'llm_top_p';
  SELECT value::JSONB INTO STRICT v_llm_stop FROM app_settings WHERE key = 'llm_stop';

  -- Build options object
  v_llm_options := jsonb_build_object(
    'temperature', v_llm_temperature,
    'num_predict', v_llm_num_predict,
    'top_p', v_llm_top_p,
    'stop', v_llm_stop
  );

  -- Build request body
  v_request_body := jsonb_build_object(
    'prompt', p_prompt,
    'model', v_llm_model,
    'options', v_llm_options
  );
  
  IF p_format IS NOT NULL THEN
    v_request_body := v_request_body || jsonb_build_object('format', p_format);
  END IF;

  RAISE NOTICE 'Calling call-llm at: %', v_edge_function_url;

  -- ============================================================================
  -- HTTP CALL TO EDGE FUNCTION
  -- ============================================================================
  -- Note: http extension timeout is set globally in PostgreSQL config
  SELECT * INTO v_response FROM extensions.http((
    'POST',
    v_edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    v_request_body::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', v_response.status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================
  IF v_response.status != 200 THEN
    RAISE EXCEPTION 'LLM call failed with status %: %', v_response.status, v_response.content;
  END IF;

  -- Parse LLM response
  v_llm_response := (v_response.content::jsonb->>'response')::text;

  RETURN v_llm_response;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'LLM API call failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."call_llm_api" ("p_prompt" "text", "p_format" "text") owner TO "postgres";


comment ON function "public"."call_llm_api" ("p_prompt" "text", "p_format" "text") IS 'Call LLM via call-llm edge function with database-driven configuration.

Fetches LLM settings from app_settings and passes them to the edge function.

Parameters:
- p_prompt: The prompt to send to the LLM
- p_format: Optional format hint (e.g., "json" for JSON responses)

Returns: LLM response text

Configuration (from app_settings - REQUIRED):
- llm_model: Ollama model name
- llm_temperature: Temperature 0.0-1.0
- llm_num_predict: Max tokens to generate
- llm_top_p: Top-p sampling 0.0-1.0
- llm_stop: JSON array of stop sequences
- Uses current_setting(''app.supabase_url'', true) with fallback to local dev
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Error handling:
- Raises exception if any required app_settings are missing
- Raises exception on HTTP error
- Raises exception on parsing failure';
