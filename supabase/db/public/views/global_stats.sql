-- View: global_stats
-- Schema: public
-- Description: Provides global game statistics for analytics and leaderboards
-- Only accessible to service_role for privacy
CREATE OR REPLACE VIEW "public"."global_stats" AS
SELECT
  -- Global session counts
  count(*) AS total_sessions,
  count(
    CASE
      WHEN was_correct = TRUE THEN 1
    END
  ) AS sessions_won,
  count(
    CASE
      WHEN was_correct = FALSE THEN 1
    END
  ) AS sessions_lost,
  count(
    CASE
      WHEN was_correct IS NULL
      AND next_turn IS NULL THEN 1
    END
  ) AS sessions_submitted,
  count(
    CASE
      WHEN next_turn IS NOT NULL THEN 1
    END
  ) AS active_sessions,
  -- Global win rate
  CASE
    WHEN count(
      CASE
        WHEN was_correct IS NOT NULL THEN 1
      END
    ) = 0 THEN 0
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
  END AS global_win_rate_percent,
  -- Unique users
  count(DISTINCT user_id) AS unique_users,
  count(
    DISTINCT CASE
      WHEN user_id IS NULL THEN 'anonymous'::TEXT
      ELSE user_id::TEXT
    END
  ) AS total_players,
  -- Average questions per completed session
  round(
    avg(
      CASE
        WHEN (
          was_correct IS NOT NULL
          OR (
            was_correct IS NULL
            AND next_turn IS NULL
          )
        ) THEN (
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
  ) AS avg_questions_per_session,
  -- Most popular places (most guessed)
  (
    SELECT
      jsonb_agg(
        jsonb_build_object(
          'place_id',
          t.place_id,
          'place_name',
          t.place_name,
          'times_guessed',
          t.times_guessed
        )
        ORDER BY
          t.times_guessed DESC
      )
    FROM
      (
        SELECT
          gs2.place_id,
          p.name AS place_name,
          count(*) AS times_guessed
        FROM
          game_sessions gs2
          JOIN places p ON gs2.place_id = p.id
        WHERE
          gs2.place_id IS NOT NULL
        GROUP BY
          gs2.place_id,
          p.name
        ORDER BY
          count(*) DESC
        LIMIT
          10
      ) t
  ) AS top_places_guessed,
  -- Recent activity (last 24 hours)
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '24 hours' THEN 1
    END
  ) AS sessions_last_24h,
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '7 days' THEN 1
    END
  ) AS sessions_last_7d,
  count(
    CASE
      WHEN created_at >= now() - INTERVAL '30 days' THEN 1
    END
  ) AS sessions_last_30d,
  -- Database stats
  (
    SELECT
      count(*)
    FROM
      places
  ) AS total_places,
  (
    SELECT
      count(*)
    FROM
      place_traits
  ) AS total_traits,
  (
    SELECT
      count(*)
    FROM
      game_logic.embeddings
  ) AS total_embeddings
FROM
  game_sessions gs;


ALTER VIEW "public"."global_stats" owner TO "postgres";


-- Permissions
REVOKE ALL ON TABLE public.global_stats
FROM
  public;


REVOKE ALL ON TABLE public.global_stats
FROM
  anon;


GRANT
SELECT
  ON TABLE public.global_stats TO authenticated;


GRANT
SELECT
  ON TABLE public.global_stats TO service_role;
