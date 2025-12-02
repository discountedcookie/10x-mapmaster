-- Function: filter_semantic_candidates
-- Category: game
-- Purpose: Calculate semantic similarity scores using softmax-weighted trait aggregation
-- Returns: Place IDs with aggregated similarity scores
CREATE OR REPLACE FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) returns TABLE (
  place_id UUID,
  base_description_similarity DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_description_embedding vector(384);
  v_threshold FLOAT;
  v_temperature FLOAT;
BEGIN
  -- Get configuration from game_logic.config
  v_threshold := get_config_float('scoring.initial_candidate_threshold', 0.5);
  v_temperature := get_config_float('scoring.trait_aggregation_temperature', 0.1);

  -- Get session embedding
  SELECT
    e.embedding
  INTO
    v_description_embedding
  FROM game_sessions gs
  JOIN embeddings e ON e.id = gs.embedding_id
  WHERE gs.id = p_session_id;

  IF v_description_embedding IS NULL THEN
    RAISE EXCEPTION 'Session % not found or has no description embedding', p_session_id;
  END IF;

  -- Calculate softmax-weighted trait similarity aggregation
  -- Formula: score = Σ(softmax(sim/τ) × sim)
  -- where softmax(sim_i/τ) = exp(sim_i/τ) / Σexp(sim_j/τ)
  RETURN QUERY
  WITH trait_similarities AS (
    -- Calculate similarity between description and each trait for each place
    SELECT
      pt.place_id AS pid,
      (1 - (te.embedding <=> v_description_embedding))::DOUBLE PRECISION AS sim
    FROM
      place_traits pt
      JOIN traits t ON t.id = pt.trait_id
      JOIN embeddings te ON te.id = t.embedding_id
    WHERE
      pt.place_id = ANY (p_place_ids)
      AND te.embedding IS NOT NULL
  ),
  exp_similarities AS (
    -- Calculate exp(sim/τ) for softmax
    SELECT
      pid,
      sim,
      exp(sim / v_temperature) AS exp_sim
    FROM trait_similarities
  ),
  softmax_weights AS (
    -- Calculate softmax weights: exp(sim/τ) / Σexp(sim/τ)
    SELECT
      pid,
      sim,
      exp_sim,
      SUM(exp_sim) OVER (PARTITION BY pid) AS sum_exp
    FROM exp_similarities
  ),
  aggregated_scores AS (
    -- Calculate weighted average: Σ(weight × sim)
    SELECT
      pid AS place_id,
      SUM((exp_sim / NULLIF(sum_exp, 0)) * sim)::DOUBLE PRECISION AS aggregated_score
    FROM softmax_weights
    GROUP BY pid
  )
  SELECT
    a.place_id,
    a.aggregated_score AS base_description_similarity
  FROM aggregated_scores a
  WHERE a.aggregated_score > v_threshold;
END;
$$;


ALTER FUNCTION "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) owner TO "postgres";


comment ON function "game_logic"."filter_semantic_candidates" ("p_session_id" UUID, "p_place_ids" UUID[]) IS 'Calculates semantic similarity using softmax-weighted trait aggregation.

Algorithm:
1. For each place, compute similarity between description and each trait embedding
2. Apply softmax weighting: weight_i = exp(sim_i/τ) / Σexp(sim_j/τ)
3. Calculate weighted average: score = Σ(weight_i × sim_i)
4. Filter by threshold

The softmax temperature (τ) controls how much the best traits dominate:
- τ → 0: Approaches MAX (only best trait matters)
- τ = 0.1: Top 2-3 traits dominate (default)
- τ → ∞: Approaches simple average

This approach handles both:
- Categorical queries ("religious site") - matches specific traits well
- Specific queries ("tall iron tower in Paris") - multiple traits contribute

Input:
- p_session_id: Session to get description embedding from
- p_place_ids: Array of place IDs to score

Returns: place_id and aggregated score for places above threshold.

Called by: get_candidates() which joins with geographic results.';
