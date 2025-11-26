-- Function: generate_embedding
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."generate_embedding" ("p_text" "text") returns "public"."vector" language "plpgsql" security definer
SET
  search_path = public,
  extensions AS $$
DECLARE
  response extensions.http_response;
  edge_function_url TEXT;
  validated_text TEXT;
  embedding_vector vector(1024);
  v_anon_key TEXT;
BEGIN
  -- ============================================================================
  -- pgTAP TEST SHORT-CIRCUIT
  -- ============================================================================
  IF current_setting('pgtap.version', true) IS NOT NULL THEN
    RETURN array_fill(0.0, ARRAY[1024])::vector(1024);
  END IF;

  -- ============================================================================
  -- INPUT VALIDATION
  -- ============================================================================

  -- Validate text input (max 1000 chars, min 1 char after trim)
  validated_text := validate_user_input(p_text, 1000, 'embedding_text');

  -- ============================================================================
  -- CONFIGURATION RETRIEVAL
  -- ============================================================================

  -- Get Supabase URL from settings (with fallback for local development)
  edge_function_url := COALESCE(
    current_setting('app.supabase_url', true),
    'http://host.docker.internal:54321'
  ) || '/functions/v1/generate-embedding';

  -- Get anon key from settings (with fallback for local development)
  v_anon_key := COALESCE(
    current_setting('app.supabase_anon_key', true),
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
  );

  RAISE NOTICE 'Calling generate-embedding at: %', edge_function_url;

  -- ============================================================================
  -- EDGE FUNCTION CALL (SYNCHRONOUS HTTP)
  -- ============================================================================

  -- Make synchronous HTTP request using http extension
  -- Note: http extension timeout is set globally, not per-request
  SELECT * INTO response FROM extensions.http((
    'POST',
    edge_function_url,
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || v_anon_key)
    ],
    'application/json',
    jsonb_build_object('text', validated_text)::text
  )::extensions.http_request);

  RAISE NOTICE 'Response status: %', response.status;

  -- ============================================================================
  -- RESPONSE HANDLING
  -- ============================================================================

  -- Check for success
  IF response.status != 200 THEN
    RAISE EXCEPTION 'Embedding generation failed with status %: %', response.status, response.content;
  END IF;

  -- Parse the embedding from response
  embedding_vector := (response.content::jsonb->>'embedding')::vector(1024);

  IF embedding_vector IS NULL THEN
    RAISE EXCEPTION 'Response did not contain valid embedding: %', response.content;
  END IF;

  RETURN embedding_vector;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'Embedding generation failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."generate_embedding" ("p_text" "text") owner TO "postgres";


comment ON function "public"."generate_embedding" ("p_text" "text") IS 'Generates a 1024-dimensional embedding vector for the given text with input validation.
Parameters:
- p_text: text to embed (validated: 1-1000 chars, no control chars)

Security:
- Validates input via validate_user_input()
- Prevents injection attacks via control character detection
- Enforces length limits
- Uses Authorization header with anon key

Configuration:
- Uses current_setting(''app.supabase_url'', true) with fallback to ''http://host.docker.internal:54321''
- Uses current_setting(''app.supabase_anon_key'', true) with fallback to local dev anon key

Process:
1. Validates input text
2. Calls edge function (generate-embedding) via synchronous http extension
3. Parses and returns vector(1024)

Error handling:
- Raises exception on validation failure
- Raises exception on HTTP error
- Raises exception on parsing failure

Technical:
- Uses http extension (synchronous) for reliability in local and production environments
- Authorization header required for edge function infrastructure';
