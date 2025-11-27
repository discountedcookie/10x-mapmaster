-- Function: generate_question_text
-- Category: utilities
-- Purpose: Generate natural language question text using LLM via call_llm_api
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
  v_llm_response TEXT;
  v_question_text TEXT;
BEGIN
  -- Get trait or region context
  IF p_trait_id IS NOT NULL THEN
    SELECT clause INTO v_trait_clause
    FROM traits
    WHERE id = p_trait_id;
    
    IF v_trait_clause IS NULL THEN
      RAISE EXCEPTION 'Trait % not found in traits table', p_trait_id;
    END IF;
    
    -- Build semantic question prompt
    v_prompt := 'Generate a natural yes/no question to ask about a place. ' ||
      'The question should ask whether the place has this characteristic: "' || v_trait_clause || '". ' ||
      'Make it conversational and natural, not robotic. ' ||
      'Output ONLY the question, nothing else. ' ||
      'Language: ' || p_language_code;
    
  ELSIF p_region_id IS NOT NULL THEN
    SELECT name INTO v_region_name
    FROM geographic_regions
    WHERE id = p_region_id;
    
    IF v_region_name IS NULL THEN
      RAISE EXCEPTION 'Geographic region % not found', p_region_id;
    END IF;
    
    -- Build geographic question prompt
    v_prompt := 'Generate a natural yes/no question to ask about a place''s location. ' ||
      'The question should ask whether the place is in: "' || v_region_name || '". ' ||
      'Make it conversational and natural, not robotic. ' ||
      'Output ONLY the question, nothing else. ' ||
      'Language: ' || p_language_code;
    
  ELSE
    RAISE EXCEPTION 'Either trait_id or region_id must be provided';
  END IF;
  
  -- Call LLM via call_llm_api - no fallback, fail if LLM fails
  v_llm_response := call_llm_api(v_prompt);
  v_question_text := trim(v_llm_response);
  
  IF v_question_text IS NULL OR v_question_text = '' THEN
    RAISE EXCEPTION 'LLM returned empty response for question generation';
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
3. Call call-llm edge function via call_llm_api
4. Extract question text from response

Errors:
- Raises exception if trait/region not found
- Raises exception if LLM call fails (no fallback)

Returns: Natural language question text ending with "?"';
