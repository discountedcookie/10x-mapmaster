-- Function: generate_question_text
-- Category: utilities
-- Purpose: Generate natural language question text using LLM via edge function
CREATE OR REPLACE FUNCTION "game_logic"."generate_question_text" (
  p_trait_id TEXT,
  p_region_id UUID,
  p_language_code TEXT DEFAULT 'en'
) returns TEXT language plpgsql security definer
SET
  search_path = public, extensions, game_logic AS $$
DECLARE
  v_trait_clause TEXT;
  v_region_name TEXT;
  v_prompt TEXT;
  v_llm_response JSONB;
  v_question_text TEXT;
BEGIN
  -- Get trait or region context
  IF p_trait_id IS NOT NULL THEN
    SELECT clause INTO v_trait_clause
    FROM traits
    WHERE id = p_trait_id;
    
    IF v_trait_clause IS NULL THEN
      RAISE EXCEPTION 'Trait % not found', p_trait_id;
    END IF;
    
    -- Build semantic question prompt
    v_prompt := jsonb_build_object(
      'type', 'semantic_question',
      'trait', v_trait_clause,
      'language', p_language_code
    );
    
  ELSIF p_region_id IS NOT NULL THEN
    SELECT name INTO v_region_name
    FROM geographic_regions
    WHERE id = p_region_id;
    
    IF v_region_name IS NULL THEN
      RAISE EXCEPTION 'Geographic region % not found', p_region_id;
    END IF;
    
    -- Build geographic question prompt
    v_prompt := jsonb_build_object(
      'type', 'geographic_question',
      'region', v_region_name,
      'language', p_language_code
    );
    
  ELSE
    RAISE EXCEPTION 'Either trait_id or region_id must be provided';
  END IF;
  
  -- Call LLM edge function
  v_llm_response := http_call_edge_function(
    'call-llm',
    'POST',
    '{}',
    v_prompt
  );
  
  -- Extract question text from response
  v_question_text := v_llm_response->>'question';
  
  IF v_question_text IS NULL OR v_question_text = '' THEN
    -- Fallback to template if LLM fails
    IF p_trait_id IS NOT NULL THEN
      v_question_text := 'Does it have ' || v_trait_clause || '?';
    ELSE
      v_question_text := 'Is it in ' || v_region_name || '?';
    END IF;
  END IF;
  
  -- Ensure question ends with question mark
  IF v_question_text NOT LIKE '%?' THEN
    v_question_text := v_question_text || '?';
  END IF;
  
  RETURN v_question_text;
END;
$$;


ALTER FUNCTION "game_logic"."generate_question_text" (
  p_trait_id TEXT,
  p_region_id UUID,
  p_language_code TEXT
) owner TO "postgres";


comment ON function "game_logic"."generate_question_text" (
  p_trait_id TEXT,
  p_region_id UUID,
  p_language_code TEXT
) IS 'Generate natural language question text using LLM via edge function.

Parameters:
- p_trait_id: Trait ID for semantic questions (optional)
- p_region_id: Geographic region ID for geographic questions (optional)
- p_language_code: Language code (default: en)

Process:
1. Get trait clause or region name from database
2. Build appropriate prompt for LLM
3. Call call-llm edge function via http_call_edge_function
4. Extract question text from response
5. Fallback to template if LLM fails

Returns: Natural language question text ending with "?"';
