-- Function: get_active_prompt
-- Category: utilities
-- Returns the active system prompt from app_settings
CREATE OR REPLACE FUNCTION "public"."get_active_prompt" () returns TEXT language plpgsql security definer
SET
  search_path = public AS $$
DECLARE
  v_prompt TEXT;
BEGIN
  -- Fetch the system prompt
  SELECT value INTO v_prompt
  FROM app_settings
  WHERE key = 'llm_prompt'
  LIMIT 1;

  -- Return the prompt, or NULL if not configured
  RETURN v_prompt;
END;
$$;


ALTER FUNCTION "public"."get_active_prompt" () owner TO "postgres";


comment ON function "public"."get_active_prompt" () IS 'Retrieves system prompt from app_settings (key: llm_prompt).

Returns NULL if no prompt is configured.
Used by LLM-calling functions to fetch DB-configurable prompt.
Prompt supports placeholders like {question_list} which are replaced by the caller.';
