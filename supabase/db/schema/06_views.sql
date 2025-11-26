-- ============================================================================
-- Database Views
-- ============================================================================
-- Description: Views that expose game state data to frontend
-- Dependencies: Tables (02_tables.sql)
-- ============================================================================
-- ============================================================================
-- game_session_state view
-- ============================================================================
-- Exposes all game state data needed by frontend UI in a single query
-- Calculates derived status from session state (was_correct, next_turn)
-- RLS is inherited from game_sessions table - view only shows rows user can access
--
-- Status Derivation Logic:
-- - 'won': User guessed correctly (was_correct = TRUE)
-- - 'ended': Hit 5-turn limit without winning (was_correct = FALSE)
-- - 'needs_submission': Zero candidates, needs manual place submission (next_turn = NULL, was_correct = NULL)
-- - 'active': Game in progress (next_turn != NULL)
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


-- ============================================================================
-- user_stats view
-- ============================================================================
-- Provides user-specific game statistics and performance metrics
-- RLS is inherited from game_sessions table - view only shows rows user can access
CREATE OR REPLACE VIEW "public"."user_stats" AS
SELECT
  -- Session counts
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
  -- Win rate (excluding submitted sessions)
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
  END AS win_rate_percent,
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
  -- Most recent activity
  max(created_at) AS last_session_at,
  max(
    CASE
      WHEN was_correct = TRUE THEN created_at
    END
  ) AS last_win_at,
  -- Current streak (consecutive wins)
  (
    WITH
      ranked_sessions AS (
        SELECT
          created_at,
          was_correct,
          row_number() OVER (
            ORDER BY
              created_at DESC
          ) AS rn
        FROM
          game_sessions
        WHERE
          user_id = auth.uid ()
          AND was_correct IS NOT NULL
      )
    SELECT
      count(*)
    FROM
      ranked_sessions
    WHERE
      was_correct = TRUE
      AND created_at >= coalesce(
        (
          SELECT
            max(created_at)
          FROM
            ranked_sessions
          WHERE
            was_correct = FALSE
            AND rn = 1
        ),
        '1970-01-01'::TIMESTAMP
      )
  ) AS current_win_streak,
  -- Best streak (all time)
  (
    WITH
      streak_groups AS (
        SELECT
          was_correct,
          created_at,
          sum(
            CASE
              WHEN was_correct = FALSE THEN 1
              ELSE 0
            END
          ) OVER (
            ORDER BY
              created_at
          ) AS streak_group
        FROM
          game_sessions
        WHERE
          user_id = auth.uid ()
          AND was_correct IS NOT NULL
      ),
      streak_lengths AS (
        SELECT
          count(*) AS streak_length
        FROM
          streak_groups
        WHERE
          was_correct = TRUE
        GROUP BY
          streak_group
      )
    SELECT
      coalesce(max(streak_length), 0)
    FROM
      streak_lengths
  ) AS best_win_streak
FROM
  game_sessions gs
WHERE
  gs.user_id = auth.uid ()
  OR gs.user_id IS NULL
GROUP BY
  gs.user_id;


ALTER VIEW "public"."user_stats" owner TO "postgres";


-- ============================================================================
-- global_stats view
-- ============================================================================
-- Provides global game statistics for analytics and leaderboards
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
      embeddings
  ) AS total_embeddings
FROM
  game_sessions gs;


ALTER VIEW "public"."global_stats" owner TO "postgres";


-- ============================================================================
-- View Permissions
-- ============================================================================
-- Restrict view access explicitly (views created above, permissions applied here)
REVOKE ALL ON TABLE public.user_stats
FROM
  public;


REVOKE ALL ON TABLE public.user_stats
FROM
  anon;


REVOKE ALL ON TABLE public.global_stats
FROM
  public;


REVOKE ALL ON TABLE public.global_stats
FROM
  anon;


GRANT
SELECT
  ON TABLE public.user_stats TO authenticated;


GRANT
SELECT
  ON TABLE public.user_stats TO service_role;


GRANT
SELECT
  ON TABLE public.global_stats TO service_role;
