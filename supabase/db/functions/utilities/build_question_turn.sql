-- Function: build_question_turn
-- Category: utilities
-- Purpose: Pure function to build question next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) returns JSONB language plpgsql immutable AS $$
BEGIN
  RETURN jsonb_build_object(
    'action', 'question',
    'question_type', p_question_type,
    'question_text', p_question_text,
    'question_reasoning', COALESCE(p_question_reasoning, ''),
    'candidates', p_candidates
  ) || 
  CASE 
    WHEN p_trait_id IS NOT NULL THEN 
      jsonb_build_object('trait_id', p_trait_id)
    WHEN p_geographic_region_id IS NOT NULL THEN 
      jsonb_build_object('geographic_region_id', p_geographic_region_id)
    ELSE '{}'::jsonb
  END;
END;
$$;


ALTER FUNCTION "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) owner TO "postgres";


comment ON function "public"."build_question_turn" (
  "p_question_type" question_type,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID,
  "p_question_text" TEXT,
  "p_question_reasoning" TEXT,
  "p_candidates" JSONB
) IS 'Pure function to build question next_turn JSONB.

IMMUTABLE: Same inputs always produce same output (no side effects).

Parameters:
- p_question_type: ''semantic'' or ''geographic''
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
- p_question_text: Generated question text
- p_question_reasoning: Optional short explanation of why the question was chosen
- p_candidates: Current candidates array

Returns JSONB structure:
{
  "action": "question",
  "question_type": "semantic" | "geographic",
  "question_text": "Does it have ...?" | "Is it in ...?",
  "question_reasoning": "...",
  "candidates": [...],
  "trait_id": "..." | "geographic_region_id": "..."
}

Extracted from decide_next_turn for Single Responsibility Principle.';
