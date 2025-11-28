-- Function: call_llm_api
-- Category: utilities
-- Purpose: Call LLM via edge function with a prompt
-- Returns: LLM response text
CREATE OR REPLACE FUNCTION "game_logic"."call_llm_api" (
  "p_prompt" "text", 
  "p_format" "text" DEFAULT NULL,
  "p_config_prefix" "text" DEFAULT 'llm'
) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
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
  v_format TEXT;
BEGIN
  -- Increase statement timeout for slower LLM responses (default 5s is too short)
  PERFORM set_config('statement_timeout', '15s', true);
  -- Increase HTTP timeout (default 5s) so curl waits for Ollama
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '15000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '5000');
  -- ============================================================================
  -- CONFIGURATION (from GUC vars or game_logic.config - NO hardcoded secrets)
  -- ============================================================================
  v_edge_function_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF v_edge_function_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  v_edge_function_url := v_edge_function_url || '/functions/v1/call-llm';

  v_anon_key := COALESCE(
    NULLIF(current_setting('app.supabase_anon_key', true), ''),
    get_config_text('runtime.supabase_anon_key')
  );
  
  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_anon_key or runtime.supabase_anon_key';
  END IF;

  -- ============================================================================
  -- FETCH LLM SETTINGS FROM game_logic.config
  -- ============================================================================
  v_llm_model := get_config_text(p_config_prefix || '.model');
  v_llm_temperature := get_config_float(p_config_prefix || '.temperature');
  v_llm_num_predict := get_config_int(p_config_prefix || '.num_predict');
  v_llm_top_p := get_config_float(p_config_prefix || '.top_p');
  v_llm_stop := get_config(p_config_prefix || '.stop');
  v_format := COALESCE(p_format, get_config_text(p_config_prefix || '.format'));

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
  
  IF v_format IS NOT NULL THEN
    v_request_body := v_request_body || jsonb_build_object('format', v_format);
  END IF;

  RAISE NOTICE 'Calling call-llm at: % with model: %', v_edge_function_url, v_llm_model;

  -- ============================================================================
  -- HTTP CALL TO EDGE FUNCTION
  -- ============================================================================
  -- Note: Select specific columns to avoid TupleDesc resource leak
  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'POST',
    v_edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    v_request_body::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', v_status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================
  IF v_status != 200 THEN
    RAISE EXCEPTION 'LLM call failed with status %: %', v_status, v_content;
  END IF;

  -- Parse LLM response
  v_llm_response := (v_content::jsonb->>'response')::text;

  RETURN v_llm_response;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'LLM API call failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."call_llm_api" ("p_prompt" "text", "p_format" "text", "p_config_prefix" "text") owner TO "postgres";


comment ON function "game_logic"."call_llm_api" ("p_prompt" "text", "p_format" "text", "p_config_prefix" "text") IS 'Call LLM via call-llm edge function with database-driven configuration.

Fetches LLM settings from game_logic.config and passes them to the edge function.

Parameters:
- p_prompt: The prompt to send to the LLM
- p_format: Optional format hint (e.g., "json" for JSON responses)
- p_config_prefix: Config key prefix for use-case specific settings (default: "llm")
  Examples: "llm.trait_extraction", "llm.question"

Returns: LLM response text

Configuration (from game_logic.config with prefix, falls back to llm.*):
- {prefix}.model: Ollama model name (default: gemma3:1b)
- {prefix}.temperature: Temperature 0.0-1.0 (default: 0.1)
- {prefix}.num_predict: Max tokens to generate (default: 300)
- {prefix}.top_p: Top-p sampling 0.0-1.0 (default: 0.9)
- {prefix}.stop: JSON array of stop sequences (default: ["\\n\\n"])

Error handling:
- Uses sensible defaults if config not found
- Raises exception on HTTP error
- Raises exception on parsing failure';
