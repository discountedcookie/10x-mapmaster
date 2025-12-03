-- Function: generate_question_text
-- Category: utilities
-- Purpose: Generate natural language question text using LLM via call_llm_api
CREATE OR REPLACE FUNCTION "game_logic"."generate_question_text" (
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT DEFAULT 'en',
  p_user_description TEXT DEFAULT '',
  p_turn_number INT DEFAULT 1
) returns TEXT language plpgsql security definer
SET
  search_path = public,
  extensions,
  game_logic AS $$
DECLARE
  v_trait_clause TEXT;
  v_region_name TEXT;
  v_prompt_template TEXT;
  v_prompt TEXT;
  v_llm_response TEXT;
  v_question_text TEXT;
  v_prompt_key TEXT;
BEGIN
  -- Get trait or region context and build prompt from config template
  -- Turn 1 uses prompts that extract noun from user description
  -- Turn 2+ uses simpler prompts with "it" as subject
  IF p_trait_id IS NOT NULL THEN
    SELECT clause INTO v_trait_clause
    FROM traits
    WHERE id = p_trait_id;
    
    IF v_trait_clause IS NULL THEN
      RAISE EXCEPTION 'Trait % not found in traits table', p_trait_id;
    END IF;
    
    -- Select prompt based on turn number
    IF p_turn_number = 1 THEN
      v_prompt_key := 'llm.question.trait_prompt_turn1';
    ELSE
      v_prompt_key := 'llm.question.trait_prompt';
    END IF;
    
    v_prompt_template := get_config_text(v_prompt_key);
    v_prompt := replace(v_prompt_template, '{trait_clause}', v_trait_clause);
    v_prompt := replace(v_prompt, '{language_code}', p_language_code);
    v_prompt := replace(v_prompt, '{user_description}', COALESCE(p_user_description, ''));
    
  ELSIF p_region_id IS NOT NULL THEN
    SELECT name INTO v_region_name
    FROM geographic_regions
    WHERE id = p_region_id;
    
    IF v_region_name IS NULL THEN
      RAISE EXCEPTION 'Geographic region % not found', p_region_id;
    END IF;
    
    -- Select prompt based on turn number
    IF p_turn_number = 1 THEN
      v_prompt_key := 'llm.question.region_prompt_turn1';
    ELSE
      v_prompt_key := 'llm.question.region_prompt';
    END IF;
    
    v_prompt_template := get_config_text(v_prompt_key);
    v_prompt := replace(v_prompt_template, '{region_name}', v_region_name);
    v_prompt := replace(v_prompt, '{language_code}', p_language_code);
    v_prompt := replace(v_prompt, '{user_description}', COALESCE(p_user_description, ''));
    
  ELSE
    RAISE EXCEPTION 'Either trait_id or region_id must be provided';
  END IF;
  
  -- Call LLM via call_llm_api with question-specific config - no fallback, fail if LLM fails
  v_llm_response := call_llm_api(v_prompt, NULL, 'llm.question');
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
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT,
  p_user_description TEXT,
  p_turn_number INT
) owner TO "postgres";


comment ON function "game_logic"."generate_question_text" (
  p_trait_id UUID,
  p_region_id UUID,
  p_language_code TEXT,
  p_user_description TEXT,
  p_turn_number INT
) IS 'Generate natural language question text using LLM.

Parameters:
- p_trait_id: Trait ID for semantic questions (optional)
- p_region_id: Geographic region ID for geographic questions (optional)
- p_language_code: Language code for the question output
- p_user_description: Original user description for context
- p_turn_number: Current turn number (1 = first question, uses noun extraction)

Turn 1 uses prompts that extract noun from user description for natural phrasing.
Turn 2+ uses simpler prompts with "it" as subject since context is established.

Returns: Natural language question text in the requested language.';
