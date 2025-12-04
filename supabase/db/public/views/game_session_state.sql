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
  -- Filter candidates above threshold and renormalize probabilities to sum to 100%
  coalesce(
    (
      WITH threshold AS (
        SELECT (value)::float as min_prob FROM game_logic.config WHERE key = 'scoring.min_display_probability'
      ),
      filtered AS (
        SELECT c, (c->>'probability')::float as prob
        FROM jsonb_array_elements(gs.next_turn -> 'candidates') c, threshold
        WHERE (c->>'probability')::float >= threshold.min_prob
      ),
      total AS (
        SELECT sum(prob) as sum_prob FROM filtered
      )
      SELECT jsonb_agg(
        jsonb_set(filtered.c, '{probability}', to_jsonb(filtered.prob / total.sum_prob))
        ORDER BY filtered.prob DESC
      )
      FROM filtered, total
    ),
    '[]'::JSONB
  ) AS candidates,
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
  gs.user_id = auth.uid ();


ALTER VIEW "public"."game_session_state" owner TO "postgres";
