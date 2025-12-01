-- View: game_session_state
-- Schema: public
-- Description: Exposes all game state data needed by frontend UI in a single query
-- Calculates derived status from session state (was_correct, next_turn)
-- RLS is inherited from game_sessions table - view only shows rows user can access
--
-- Status Derivation Logic:
-- - 'won': User guessed correctly (was_correct = TRUE)
-- - 'ended': Game ended and place was submitted (place_id IS NOT NULL, not won)
-- - 'needs_submission': Game ended without winning, no place submitted yet
-- - 'active': Game in progress
CREATE OR REPLACE VIEW "public"."game_session_state" AS
SELECT
  -- Session metadata
  gs.id AS session_id,
  gs.description,
  -- Derived status (calculated from state, not stored)
  CASE
    WHEN gs.was_correct = TRUE THEN 'won'::game_session_status
    WHEN gs.next_turn IS NULL
    AND gs.place_id IS NOT NULL THEN 'ended'::game_session_status
    WHEN gs.next_turn IS NULL THEN 'needs_submission'::game_session_status
    WHEN gs.next_turn ->> 'action' = 'give_up' THEN 'needs_submission'::game_session_status
    ELSE 'active'::game_session_status
  END AS status,
  -- Structured frontend JSON blobs
  CASE
    WHEN gs.next_turn ->> 'action' = 'question' THEN jsonb_build_object(
      'id',
      gs.next_turn ->> 'question_id',
      'text',
      gs.next_turn ->> 'question_text'
    )
    ELSE NULL
  END AS question,
  CASE
    WHEN gs.next_turn ->> 'action' = 'guess' THEN jsonb_build_object(
      'place_id',
      gs.next_turn ->> 'place_id',
      'place_name',
      gs.next_turn ->> 'place_name'
    )
    ELSE NULL
  END AS guess,
  CASE
    WHEN gs.place_id IS NULL THEN NULL
    ELSE jsonb_build_object(
      'id',
      gs.place_id,
      'name',
      wp.name,
      'lat',
      wp.lat,
      'lng',
      wp.lng
    )
  END AS place,
  coalesce(gs.next_turn -> 'candidates', '[]'::JSONB) AS candidates,
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
