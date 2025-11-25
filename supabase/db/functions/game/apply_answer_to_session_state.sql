-- Function: apply_answer_to_session_state
-- Category: game
-- Applies a player's answer to the session state by updating affirmed/denied traits
-- and regenerating trait embeddings used by get_candidates
CREATE OR REPLACE FUNCTION "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) returns void language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_session_record RECORD;
  v_affirmed_ids TEXT[] := ARRAY[]::TEXT[];
  v_denied_ids TEXT[] := ARRAY[]::TEXT[];
  v_description TEXT := '';
  v_affirmed_text TEXT;
  v_denied_text TEXT;
  v_manual_suffix TEXT;
  v_new_constraint TEXT;
  v_new_trait_embedding vector(1024);
BEGIN
  -- Get current session state
  SELECT * INTO v_session_record
  FROM game_sessions gs
  WHERE gs.id = p_session_id;
  
  IF v_session_record.id IS NULL THEN
    RAISE EXCEPTION 'Session % not found', p_session_id;
  END IF;
  
  v_affirmed_ids := COALESCE(v_session_record.affirmed_trait_ids, ARRAY[]::TEXT[]);
  v_denied_ids := COALESCE(v_session_record.denied_trait_ids, ARRAY[]::TEXT[]);
  v_description := COALESCE(v_session_record.description, '');

  -- Update canonical trait arrays when question provides a trait_id
  IF p_trait_id IS NOT NULL THEN
    IF p_answer THEN
      v_affirmed_ids := array_append(array_remove(v_affirmed_ids, p_trait_id), p_trait_id);
      v_denied_ids := array_remove(v_denied_ids, p_trait_id);
    ELSE
      v_denied_ids := array_append(array_remove(v_denied_ids, p_trait_id), p_trait_id);
      v_affirmed_ids := array_remove(v_affirmed_ids, p_trait_id);
    END IF;
  END IF;

  -- Build affirmed/denied clause strings from canonical traits
  SELECT string_agg(pt.clause, '; ' ORDER BY pt.clause)
  INTO v_affirmed_text
  FROM place_traits pt
  WHERE pt.id = ANY(v_affirmed_ids);

  SELECT string_agg(pt.clause, '; ' ORDER BY pt.clause)
  INTO v_denied_text
  FROM place_traits pt
  WHERE pt.id = ANY(v_denied_ids);

  -- Regenerate trait embeddings if anything changed
  IF v_affirmed_ids IS DISTINCT FROM v_session_record.affirmed_trait_ids
     OR v_denied_ids IS DISTINCT FROM v_session_record.denied_trait_ids THEN

    UPDATE game_sessions
    SET
      affirmed_trait_ids = v_affirmed_ids,
      denied_trait_ids = v_denied_ids,
      affirmed_trait_embedding_id = CASE 
        WHEN v_affirmed_text IS NOT NULL THEN get_or_create_embedding(v_affirmed_text)
        ELSE NULL
      END,
      denied_trait_embedding_id = CASE 
        WHEN v_denied_text IS NOT NULL THEN get_or_create_embedding(v_denied_text)
        ELSE NULL
      END
    WHERE id = p_session_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) owner TO "postgres";


comment ON function "public"."apply_answer_to_session_state" (
  "p_session_id" UUID,
  "p_answer" BOOLEAN,
  "p_trait_id" TEXT,
  "p_geographic_region_id" UUID
) IS 'Applies a user answer to the session.

Behavior:
- Uses trait_id to update affirmed/denied trait arrays (used for filtering)
- Builds trait constraint from affirmed traits
- Regenerates trait_embedding from affirmed traits (used by get_candidates)
- Geographic questions are handled separately (only affect bounding boxes)

Parameters:
- p_session_id: Session ID
- p_answer: User answer (true/false)
- p_trait_id: Trait ID for semantic questions (NULL for geographic)
- p_geographic_region_id: Region ID for geographic questions (NULL for semantic)
';
