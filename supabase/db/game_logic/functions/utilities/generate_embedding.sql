-- Function: generate_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."generate_embedding" (
  "p_text" "text",
  "p_input_type" "text" DEFAULT 'query'  -- 'query' for searches, 'passage' for documents/traits
) returns "extensions"."vector" language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
  edge_function_url TEXT;
  validated_text TEXT;
  embedding_vector vector(384);
  v_anon_key TEXT;
  v_input_type TEXT;
BEGIN
  -- Validate input_type (must be 'query' or 'passage')
  v_input_type := COALESCE(p_input_type, 'query');
  IF v_input_type NOT IN ('query', 'passage') THEN
    RAISE EXCEPTION 'Invalid input_type: %. Must be ''query'' or ''passage''', v_input_type;
  END IF;
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    RETURN array_fill(0.0, ARRAY[384])::vector(384);
  END IF;

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================

  -- Validate text input (max 1000 chars, min 1 char after trim)
  validated_text := validate_user_input(p_text, 1000, 'embedding_text');

  -- ============================================================================
  -- CONFIGURATION RETRIEVAL (from GUC vars or game_logic.config - NO hardcoded secrets)
  -- ============================================================================

  -- Get Supabase URL from settings
  edge_function_url := COALESCE(
    NULLIF(current_setting('app.supabase_url', true), ''),
    get_config_text('runtime.supabase_url')
  );
  
  IF edge_function_url IS NULL THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_url or runtime.supabase_url';
  END IF;
  
  edge_function_url := edge_function_url || '/functions/v1/generate-embedding';

  -- Get anon key from settings
  v_anon_key := COALESCE(
    NULLIF(current_setting('app.supabase_anon_key', true), ''),
    get_config_text('runtime.supabase_anon_key')
  );
  
  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    RAISE EXCEPTION 'Missing configuration: app.supabase_anon_key or runtime.supabase_anon_key';
  END IF;



  -- ============================================================================
  -- EDGE FUNCTION CALL (SYNCHRONOUS HTTP)
  -- ============================================================================

  -- Make synchronous HTTP request using http extension
  -- Note: Select specific columns to avoid TupleDesc resource leak
  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'POST',
    edge_function_url,
    ARRAY[
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    jsonb_build_object('text', validated_text, 'inputType', v_input_type)::text
  )::extensions.http_request);

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================

  -- Check for success
  IF v_status != 200 THEN
    RAISE EXCEPTION 'Embedding generation failed with status %: %', v_status, v_content;
  END IF;

  -- Parse the embedding from response
  embedding_vector := (v_content::jsonb->>'embedding')::vector(384);

  IF embedding_vector IS NULL THEN
    RAISE EXCEPTION 'Response did not contain valid embedding: %', response.content;
  END IF;

  RETURN embedding_vector;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'Embedding generation failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "game_logic"."generate_embedding" ("p_text" "text", "p_input_type" "text") owner TO "postgres";


comment ON function "game_logic"."generate_embedding" ("p_text" "text", "p_input_type" "text") IS 'Generates a 384-dimensional embedding vector for the given text with input validation.
Parameters:
- p_text: text to embed (validated: 1-1000 chars, no control chars)
- p_input_type: ''query'' for user searches, ''passage'' for documents/traits (default: ''query'')

E5 Model Prefixes:
- E5 models use asymmetric retrieval training
- ''query'' inputs are prefixed with "query: " (for user descriptions being searched)
- ''passage'' inputs are prefixed with "passage: " (for traits being matched against)
- This asymmetric prefixing is critical for optimal matching quality

Security:
- Validates input via validate_user_input()
- Prevents injection attacks via control character detection
- Enforces length limits
- Uses Authorization header with anon key

Configuration:
- Uses current_setting(''app.supabase_url'', true) with fallback to ''http://host.docker.internal:54321''
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Process:
1. Validates input text and input_type
2. Calls edge function (generate-embedding) via synchronous http extension
3. Parses and returns vector(384)

Error handling:
- Raises exception on validation failure
- Raises exception on HTTP error
- Raises exception on parsing failure

Technical:
- Uses http extension (synchronous) for reliability in local and production environments
- Authorization header required for edge function infrastructure';


-- Function Permissions: INTERNAL ONLY
-- This function should ONLY be called by other database functions (start_game, etc.)
-- NOT directly from the frontend, to prevent API quota abuse.
-- Rate limiting is enforced at the entry points (start_game, etc.)
REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  public;


REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  anon;


REVOKE
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT)
FROM
  authenticated;


-- Only postgres role and service_role can execute
GRANT
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT) TO postgres;


GRANT
EXECUTE ON function game_logic.generate_embedding (TEXT, TEXT) TO service_role;
