-- Function: get_llm_question
-- Category: questions
-- Purpose: Uses LLM to select the best question from available options
CREATE OR REPLACE FUNCTION "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) returns TABLE (
  "question_type" question_type,
  "trait_id" TEXT,
  "geographic_region_id" UUID,
  "question_text" TEXT,
  "question_reasoning" TEXT
) language plpgsql security definer
SET
  search_path = public AS $$
DECLARE
  v_prompt_template TEXT;
  v_prompt TEXT;
  v_llm_response TEXT;
  v_response_json JSONB;
  v_selected_question_text TEXT;
  v_selected_region_idx INT;
  v_semantic_trait JSONB;
  v_question_reasoning TEXT;
  v_response_question_type TEXT;
  v_description TEXT;
  v_language_code TEXT;
  v_questions_internal_json JSONB;
  v_description_section TEXT := '';
  v_candidates_section TEXT := '';
  v_previous_answers_section TEXT := '';
  v_geo_section TEXT := '';
  v_rule3_text TEXT := '';
  v_geo_output_example TEXT := '';
  v_candidates_text TEXT;
BEGIN
  IF p_available_questions IS NULL THEN
    p_available_questions := '[]'::jsonb;
  END IF;


  -- ============================================================================
  -- BUILD GAME CONTEXT
  -- ============================================================================

  -- Get description and language code
  SELECT description, description_language_code INTO v_description, v_language_code
  FROM game_sessions
  WHERE id = p_session_id;

  -- Build candidate summary text (top 5)
  WITH ranked AS (
    SELECT
      ROW_NUMBER() OVER (ORDER BY (c->>'confidence')::float DESC) as row_num,
      c->>'name' as name,
      (c->>'confidence')::float as confidence,
      c->>'known_traits' as known_traits
    FROM jsonb_array_elements(p_candidates) c
  )
  SELECT string_agg(
    format('%s. %s; confidence %s%%',
      row_num,
      NULLIF(known_traits, ''),
      LEAST(100, GREATEST(0, round(confidence::numeric * 100)::int))
    ),
    E'\n'
    ORDER BY row_num
  )
  INTO v_candidates_text
  FROM ranked
  WHERE row_num <= 5;

  IF v_description IS NOT NULL THEN
    v_description_section := '# Initial Description' || E'\n' || v_description || E'\n';
  ELSE
    v_description_section := '';
  END IF;

  IF v_candidates_text IS NOT NULL THEN
    v_candidates_section := '# Top Candidates (format: "<rank>. <traits>; confidence <xx>%")' || E'\n' || v_candidates_text || E'\n';
  ELSE
    v_candidates_section := '';
  END IF;

  v_previous_answers_section := '';
  v_geo_section := '';

  -- ============================================================================
  -- BUILD QUESTION LIST JSON
  -- ============================================================================

  WITH enumerated AS (
    SELECT
      ROW_NUMBER() OVER () as option_idx,
      q,
      COALESCE(q->>'name', q->>'trait_clause', q->>'region_name', q->>'text') as display_name
    FROM jsonb_array_elements(p_available_questions) q
  )
  SELECT
    jsonb_agg(
      jsonb_build_object(
        'idx', option_idx,
        'region_id', q->>'region_id',
        'name', display_name
      ) ORDER BY option_idx
    ) AS internal_json,
    string_agg(
      format('%s: %s', option_idx, display_name),
      E'\n'
      ORDER BY option_idx
    ) AS geo_text
  INTO v_questions_internal_json, v_geo_section
  FROM enumerated;

  IF v_geo_section IS NOT NULL THEN
    v_geo_section := '# Geographic Regions' || E'\n' || v_geo_section || E'\n\n';
    v_rule3_text := '3. Only use the "Geographic Regions" section if you cannot find any semantic trait that would split the candidates into two reasonably balanced groups.';
    v_geo_output_example := 'If choosing a Geographic Option:' || E'\n' || '{"type": "geographic", "lang": "{language}", "question": "Is it in Europe?", "region_id": <int>, "reasoning": "<reasoning>"}' || E'\n';
  ELSE
    v_geo_section := '';
    v_rule3_text := '';
    v_geo_output_example := '';
  END IF;



  -- Build previous answers text
  WITH answer_history AS (
    SELECT
      ga.question_text,
      CASE WHEN ga.answer THEN 'TRUE' ELSE 'FALSE' END AS answer_text,
      ga.created_at
    FROM game_answers ga
    WHERE ga.session_id = p_session_id
      AND (ga.trait_id IS NOT NULL OR ga.geographic_region_id IS NOT NULL)
      AND ga.question_text IS NOT NULL
  )
  SELECT string_agg(
    format('- %s → %s', answer_history.question_text, answer_history.answer_text),
    E'\n'
    ORDER BY answer_history.created_at
  )
  INTO v_previous_answers_section
  FROM answer_history;

  IF v_previous_answers_section IS NOT NULL THEN
    v_previous_answers_section := '# Previous Answers' || E'\n' || v_previous_answers_section || E'\n\n';
  ELSE
    v_previous_answers_section := '';
  END IF;


  -- ==========================================================================
  -- BUILD PROMPT WITH CONTEXT
  -- ==========================================================================

  v_prompt_template := get_active_prompt();

  IF v_prompt_template IS NULL THEN
    RAISE EXCEPTION 'llm_prompt not configured in app_settings';
  END IF;

  v_prompt := replace(v_prompt_template, '{language}', COALESCE(v_language_code, 'en'));
  v_prompt := replace(v_prompt, '{rule3}', v_rule3_text);
  v_prompt := replace(v_prompt, '{geo_example}', v_geo_output_example);
  v_prompt := replace(v_prompt, '{description}', v_description_section);
  v_prompt := replace(v_prompt, '{candidates}', v_candidates_section);
  v_prompt := replace(v_prompt, '{answers}', v_previous_answers_section);
  v_prompt := replace(v_prompt, '{geographic_regions}', v_geo_section);


  -- ============================================================================
  -- CALL LLM AND PARSE JSON RESPONSE
  -- ============================================================================

  v_llm_response := call_llm_api(v_prompt);
  v_llm_response := trim(v_llm_response);

  IF v_llm_response LIKE '```%' THEN
    v_llm_response := regexp_replace(v_llm_response, '^```[^\n]*\n', '');
    v_llm_response := regexp_replace(v_llm_response, '\n```$', '');
    v_llm_response := trim(v_llm_response);
  END IF;

  IF v_llm_response = '' THEN
    RAISE EXCEPTION 'LLM returned empty response for prompt';
  END IF;

  BEGIN
    v_response_json := v_llm_response::jsonb;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'LLM response was not valid JSON: %', v_llm_response;
  END;

  v_response_question_type := lower(trim(COALESCE(v_response_json->>'type', v_response_json->>'question_type', '')));
  v_selected_region_idx := NULLIF(COALESCE(v_response_json->>'region_id', v_response_json->>'question_id'), '')::INT;
  v_selected_question_text := trim(COALESCE(v_response_json->>'question', v_response_json->>'question_text', ''));
  v_question_reasoning := NULLIF(trim(COALESCE(v_response_json->>'reasoning', '')),'');
  v_semantic_trait := v_response_json->'semantic_trait';

  IF v_semantic_trait IS NOT NULL THEN
    IF jsonb_typeof(v_semantic_trait) = 'string' THEN
      v_semantic_trait := jsonb_build_object('canonical_name', v_semantic_trait #>> '{}');
    END IF;
    IF (v_semantic_trait ? 'canonical_name') THEN
      IF NOT (v_semantic_trait ? 'slug') OR (v_semantic_trait->>'slug') IS NULL OR v_semantic_trait->>'slug' = '' THEN
        v_semantic_trait := v_semantic_trait || jsonb_build_object(
          'slug', regexp_replace(lower(v_semantic_trait->>'canonical_name'), '[^a-z0-9]+', '_', 'g')
        );
      END IF;
    END IF;
  END IF;


  IF v_selected_question_text = '' THEN
    v_selected_question_text := NULL;
  END IF;

  IF v_selected_question_text IS NOT NULL AND v_selected_question_text NOT LIKE '%?' THEN
    v_selected_question_text := v_selected_question_text || '?';
  END IF;

  RAISE NOTICE 'LLM response JSON: %', v_response_json;

  -- ============================================================================
  -- FIND SELECTED QUESTION BY ID (LLM must return question_id for existing prompts)
  -- ============================================================================

  IF v_response_question_type = 'geographic' THEN
    IF v_selected_region_idx IS NULL THEN
      RAISE EXCEPTION 'LLM geographic response missing region_id: %', v_response_json;
    END IF;
    IF v_selected_question_text IS NULL THEN
      RAISE EXCEPTION 'LLM geographic response missing question text: %', v_response_json;
    END IF;

    RETURN QUERY
    SELECT
      'geographic'::question_type,
      NULL::text,
      (q->>'region_id')::uuid,
      v_selected_question_text,
      v_question_reasoning
    FROM jsonb_array_elements(v_questions_internal_json) q
    WHERE (q->>'idx')::int = v_selected_region_idx
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'LLM returned invalid region_id % (available: 1-%). Response: %',
        v_selected_region_idx,
        jsonb_array_length(v_questions_internal_json),
        v_response_json;
    END IF;

    RETURN;

  ELSIF v_response_question_type = 'semantic' THEN
    IF v_selected_question_text IS NULL THEN
      RAISE EXCEPTION 'LLM semantic response missing question_text: %', v_response_json;
    END IF;

    DECLARE
      v_trait_clause TEXT;
      v_trait_id TEXT;
      v_trait_slug TEXT;
    BEGIN
      IF v_semantic_trait IS NULL THEN
        RAISE EXCEPTION 'LLM semantic question missing semantic_trait metadata: %', v_llm_response;
      END IF;

      v_trait_clause := trim(COALESCE(v_semantic_trait->>'canonical_name', ''));

      IF v_trait_clause = '' THEN
        RAISE EXCEPTION 'LLM semantic question missing canonical_name in semantic_trait: %', v_llm_response;
      END IF;

      v_trait_slug := trim(COALESCE(v_semantic_trait->>'slug', ''));

      IF v_trait_slug = '' THEN
        v_trait_slug := regexp_replace(lower(v_trait_clause), '[^a-z0-9]+', '_', 'g');
      ELSE
        v_trait_slug := regexp_replace(lower(v_trait_slug), '[^a-z0-9_]', '_', 'g');
      END IF;

      IF v_trait_slug = '' THEN
        RAISE EXCEPTION 'LLM semantic question produced invalid slug in semantic_trait: %', v_llm_response;
      END IF;

      v_trait_id := 'llm_' || v_trait_slug;

      RAISE NOTICE 'LLM invented new trait: "%" with ID: %', v_trait_clause, v_trait_id;

      INSERT INTO place_traits (id, clause, category)
      VALUES (v_trait_id, v_trait_clause, 'llm_invented')
      ON CONFLICT (id) DO UPDATE SET clause = EXCLUDED.clause;

      RETURN QUERY
      SELECT
        'semantic'::question_type,
        v_trait_id,
        NULL::uuid,
        v_selected_question_text,
        v_question_reasoning;
    END;

    RETURN;
  ELSE
    RAISE EXCEPTION 'LLM response contained invalid question_type: %', v_response_json;
  END IF;

END;
$$;


ALTER FUNCTION "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) owner TO "postgres";


comment ON function "public"."get_llm_question" (
  "p_session_id" "uuid",
  "p_candidates" JSONB,
  "p_available_questions" JSONB
) IS 'Uses LLM to select best question from available options.

SECURITY DEFINER: Needs elevated privileges to INSERT invented traits into place_traits.
Session ownership is validated by calling functions (play_turn, etc).

Process:
1. Build human-readable game context (description, candidates, previous answers, geo options)
2. Call LLM via call_llm_api
3. Parse JSON response (question_type + question_text + optional semantic_trait)
4. Match response to enumerated questions for geographic selections
5. For semantic questions: ensure trait metadata, persist trait in place_traits, and return new question

Returns: question_type, trait_id/geographic_region_id, question_text';
