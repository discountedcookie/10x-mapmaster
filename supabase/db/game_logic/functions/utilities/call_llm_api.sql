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
  v_fallback_model TEXT;
  v_llm_options JSONB;
  v_json_schema JSONB;
  v_format TEXT;
  v_primary_error TEXT;
BEGIN
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    -- Return stub response for tests - avoids external HTTP calls
    RETURN 'Is it a test question';
  END IF;

  -- Increase statement timeout for slower LLM responses
  PERFORM set_config('statement_timeout', '60s', true);
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '60000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '10000');

  -- Get runtime config
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

  -- Get model config
  v_llm_model := get_config_text(p_config_prefix || '.model');
  v_fallback_model := get_config_text(p_config_prefix || '.fallback_model', NULL);
  v_json_schema := get_config(p_config_prefix || '.json_schema');
  v_format := COALESCE(p_format, get_config_text(p_config_prefix || '.format'));

  -- Build options from all available config keys (passed through to OpenRouter)
  v_llm_options := jsonb_build_object(
    'temperature', get_config_float(p_config_prefix || '.temperature'),
    'max_tokens', get_config_int(p_config_prefix || '.max_tokens'),
    'top_p', get_config_float(p_config_prefix || '.top_p'),
    'top_k', get_config_int(p_config_prefix || '.top_k', 0),
    'min_p', get_config_float(p_config_prefix || '.min_p', 0.0),
    'seed', get_config_int(p_config_prefix || '.seed', NULL),
    'stop', get_config(p_config_prefix || '.stop'),
    'frequency_penalty', get_config_float(p_config_prefix || '.frequency_penalty'),
    'presence_penalty', get_config_float(p_config_prefix || '.presence_penalty'),
    'repetition_penalty', get_config_float(p_config_prefix || '.repetition_penalty')
  );

  -- Build request body
  v_request_body := jsonb_build_object(
    'prompt', p_prompt,
    'model', v_llm_model,
    'options', v_llm_options
  );
  
  IF v_format IS NOT NULL AND v_json_schema IS NULL THEN
    v_request_body := v_request_body || jsonb_build_object('format', v_format);
  END IF;

  IF v_json_schema IS NOT NULL THEN
    v_request_body := v_request_body || jsonb_build_object('jsonSchema', v_json_schema);
  END IF;

  RAISE NOTICE 'Calling call-llm at: % with model: %', v_edge_function_url, v_llm_model;

  -- HTTP call with fallback
  BEGIN
    SELECT status, content INTO v_status, v_content FROM extensions.http((
      'POST', v_edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
      ],
      'application/json', v_request_body::text
    )::extensions.http_request);

    IF v_status != 200 THEN
      RAISE EXCEPTION 'LLM call failed with status %: %', v_status, v_content;
    END IF;

    RETURN (v_content::jsonb->>'response')::text;

  EXCEPTION WHEN others THEN
    v_primary_error := SQLERRM;
    
    IF v_fallback_model IS NOT NULL THEN
      RAISE NOTICE 'Primary model failed (%), trying fallback: %', v_primary_error, v_fallback_model;
      v_request_body := jsonb_set(v_request_body, '{model}', to_jsonb(v_fallback_model));
      
      SELECT status, content INTO v_status, v_content FROM extensions.http((
        'POST', v_edge_function_url,
        ARRAY[
          extensions.http_header('Content-Type', 'application/json'),
          extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
        ],
        'application/json', v_request_body::text
      )::extensions.http_request);

      IF v_status != 200 THEN
        RAISE EXCEPTION 'LLM fallback failed with status %: %', v_status, v_content;
      END IF;

      RETURN (v_content::jsonb->>'response')::text;
    ELSE
      RAISE EXCEPTION 'LLM API call failed: %', v_primary_error;
    END IF;
  END;
END;
$$;


ALTER FUNCTION "game_logic"."call_llm_api" (
  "p_prompt" "text",
  "p_format" "text",
  "p_config_prefix" "text"
) owner TO "postgres";


comment ON function "game_logic"."call_llm_api" (
  "p_prompt" "text",
  "p_format" "text",
  "p_config_prefix" "text"
) IS 'Call LLM via edge function with config-driven settings and optional fallback.

Parameters:
- p_prompt: The prompt to send
- p_format: Optional format hint (e.g., "json")
- p_config_prefix: Config key prefix (e.g., "llm.trait_extraction", "llm.question")

Configuration keys (from game_logic.config):
- {prefix}.model: Primary OpenRouter model ID
- {prefix}.fallback_model: Optional fallback model if primary fails
- {prefix}.temperature, max_tokens, top_p, top_k, min_p, seed, stop
- {prefix}.frequency_penalty, presence_penalty, repetition_penalty
- {prefix}.json_schema: Structured output schema (if needed)

All options are passed through to OpenRouter. Unsupported options are ignored.';
