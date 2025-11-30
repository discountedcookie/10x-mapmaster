-- View: game_session_state
-- Schema: public
-- Description: Exposes all game state data needed by frontend UI in a single query
-- Calculates derived status from session state (was_correct, next_turn)
-- RLS is inherited from game_sessions table - view only shows rows user can access
--
-- Status Derivation Logic:
-- - 'won': User guessed correctly (was_correct = TRUE)
-- - 'ended': Hit 5-turn limit without winning (was_correct = FALSE)
-- - 'needs_submission': Zero candidates OR give_up action (next_turn = NULL OR next_turn->>'action' = 'give_up')
-- - 'active': Game in progress (next_turn != NULL with question/guess action)
CREATE OR REPLACE VIEW "public"."game_session_state" AS
SELECT
  -- Session metadata
  gs.id AS session_id,
  gs.description,
  -- Derived status (calculated from state, not stored)
  CASE
    WHEN gs.was_correct = TRUE THEN 'won'::game_session_status
    WHEN gs.next_turn IS NULL
    AND gs.was_correct = FALSE THEN 'ended'::game_session_status
    WHEN gs.next_turn IS NULL THEN 'needs_submission'::game_session_status
    WHEN gs.next_turn ->> 'action' = 'give_up' THEN 'needs_submission'::game_session_status
    ELSE 'active'::game_session_status
  END AS status,
  -- Next turn action (cached)
  gs.next_turn,
  -- Flattened next_turn fields for frontend access
  gs.next_turn ->> 'question_text' AS current_question_text,
  gs.next_turn ->> 'question_id' AS current_question_id,
  gs.next_turn ->> 'place_name' AS pending_guess_place_name,
  gs.next_turn ->> 'place_id' AS pending_guess_place_id,
  -- Win state (if won)
  gs.place_id AS correct_place_id,
  wp.name AS correct_place_name,
  wp.lat AS correct_place_lat,
  wp.lng AS correct_place_lng,
  -- Metadata
  (
    SELECT
      count(*)
    FROM
      game_answers
    WHERE
      session_id = gs.id
      AND (
        trait_id IS NOT NULL
        OR geographic_region_id IS NOT NULL
      )
  ) AS question_count
FROM
  game_sessions gs
  LEFT JOIN places wp ON gs.place_id = wp.id
WHERE
  gs.user_id = auth.uid ()
  OR gs.user_id IS NULL;


ALTER VIEW "public"."game_session_state" owner TO "postgres";
