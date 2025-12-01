-- Function: learn_traits_from_session
-- Category: places
-- Purpose: Learn traits from a completed game session's answers
-- Spec: docs/architecture/algorithm.md#trait-sources
CREATE OR REPLACE FUNCTION "game_logic"."learn_traits_from_session" ("p_session_id" UUID, "p_place_id" UUID) returns JSONB language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  v_affirmed_count INT := 0;
  v_already_had_count INT := 0;
  v_trait_record RECORD;
BEGIN
  -- Learn from affirmed traits (YES answers to semantic questions)
  FOR v_trait_record IN
    SELECT ga.trait_id
    FROM game_answers ga
    WHERE ga.session_id = p_session_id
      AND ga.trait_id IS NOT NULL  -- Semantic questions only
      AND ga.answer = 'yes'        -- Affirmed traits
  LOOP
    -- Insert trait link if not already exists
    INSERT INTO place_traits (place_id, trait_id)
    VALUES (p_place_id, v_trait_record.trait_id)
    ON CONFLICT (place_id, trait_id) DO NOTHING;
    
    IF FOUND THEN
      v_affirmed_count := v_affirmed_count + 1;
    ELSE
      v_already_had_count := v_already_had_count + 1;
    END IF;
  END LOOP;
  
  -- Log learning result
  IF v_affirmed_count > 0 THEN
    RAISE NOTICE 'Learned % new traits for place % from session %', 
      v_affirmed_count, p_place_id, p_session_id;
  END IF;
  
  RETURN jsonb_build_object(
    'status', 'success',
    'traits_learned', v_affirmed_count,
    'traits_already_had', v_already_had_count,
    'session_id', p_session_id,
    'place_id', p_place_id
  );
END;
$$;


ALTER FUNCTION "game_logic"."learn_traits_from_session" (UUID, UUID) owner TO "postgres";


comment ON function "game_logic"."learn_traits_from_session" (UUID, UUID) IS 'Learns traits from a completed game session.

When a game completes successfully (user confirms the guess):
1. Gets all game_answers where trait_id IS NOT NULL and answer = ''yes''
2. Inserts those traits into place_traits (if not already there)

This enables the game to learn new traits about places over time.

Example flow:
1. User describes "tall iron structure with observation deck"
2. Game asks "Does it offer panoramic views?" (trait: feature:observation)
3. User answers YES
4. Game guesses Eiffel Tower, user confirms
5. If Eiffel Tower didn''t have feature:observation, it learns it now

Parameters:
- p_session_id: The completed session to learn from
- p_place_id: The place that was correctly guessed

Returns: JSONB with learning statistics';
