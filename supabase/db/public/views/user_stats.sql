-- View: user_stats
-- Schema: public
-- Description: Provides user-specific game statistics per spec
-- Spec columns: games_played, games_won, win_rate, avg_turns_to_win, places_added, last_played_at
-- Security: Uses security_invoker so RLS on game_sessions is respected
-- The WHERE user_id = auth.uid() provides defense-in-depth filtering
CREATE OR REPLACE VIEW "public"."user_stats"
WITH (security_invoker = on) AS
SELECT
  -- games_played: Total completed games (won or lost, not active)
  count(
    CASE
      WHEN was_correct IS NOT NULL THEN 1
    END
  ) AS games_played,
  -- games_won: Games where user guessed correctly
  count(
    CASE
      WHEN was_correct = TRUE THEN 1
    END
  ) AS games_won,
  -- win_rate: Percentage of games won (0-100)
  CASE
    WHEN count(
      CASE
        WHEN was_correct IS NOT NULL THEN 1
      END
    ) = 0 THEN 0::NUMERIC
    ELSE round(
      (
        count(
          CASE
            WHEN was_correct = TRUE THEN 1
          END
        )::NUMERIC / count(
          CASE
            WHEN was_correct IS NOT NULL THEN 1
          END
        )
      ) * 100,
      2
    )
  END AS win_rate,
  -- avg_turns_to_win: Average number of turns in winning games
  round(
    avg(
      CASE
        WHEN was_correct = TRUE THEN (
          SELECT
            count(*)
          FROM
            game_answers ga
          WHERE
            ga.session_id = gs.id
        )
        ELSE NULL
      END
    ),
    2
  ) AS avg_turns_to_win,
  -- places_added: Count of places submitted by this user
  (
    SELECT
      count(DISTINCT place_id)
    FROM
      game_sessions
    WHERE
      user_id = auth.uid ()
      AND place_id IS NOT NULL
      AND was_correct = FALSE
  ) AS places_added,
  -- last_played_at: Most recent game session
  max(created_at) AS last_played_at
FROM
  game_sessions gs
WHERE
  gs.user_id = auth.uid ()
GROUP BY
  gs.user_id;


ALTER VIEW "public"."user_stats" owner TO "postgres";


-- Permissions
REVOKE ALL ON TABLE public.user_stats
FROM
  public;


REVOKE ALL ON TABLE public.user_stats
FROM
  anon;


GRANT
SELECT
  ON TABLE public.user_stats TO authenticated;


GRANT
SELECT
  ON TABLE public.user_stats TO service_role;
