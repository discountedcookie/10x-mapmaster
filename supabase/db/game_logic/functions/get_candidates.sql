-- Function: get_candidates
-- Category: game
-- Purpose: Orchestrate candidate filtering and apply business logic (scoring weights)
-- Returns: JSONB array of candidates (use jsonb_array_length for count)
CREATE OR REPLACE FUNCTION "game_logic"."get_candidates" ("session_id_param" "uuid") returns JSONB language "plpgsql" security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_geo_fit_max_weight FLOAT;
  v_distance_normalization FLOAT;
  v_result JSONB;
BEGIN
  -- Get scoring configuration from game_logic.config
  v_geo_fit_max_weight := get_config_float('scoring.geographic_fit_max_weight', 0.2);
  v_distance_normalization := get_config_float('scoring.distance_normalization', 20000000.0);

  -- Orchestrate filtering and scoring pipeline
  WITH geographic_filtered AS (
    -- Step 1: Apply geographic filters + distance calculation (cheap PostGIS operations)
    SELECT * FROM filter_geographic_candidates(session_id_param)
  ),
  place_ids AS (
    -- Step 2: Extract place IDs to pass to semantic filter
    SELECT ARRAY_AGG(id) AS ids FROM geographic_filtered
  ),
  semantic_scored AS (
    -- Step 3: Calculate semantic similarities for filtered places (expensive vector operations)
    SELECT * 
    FROM filter_semantic_candidates(session_id_param, (SELECT ids FROM place_ids))
    WHERE (SELECT ids FROM place_ids) IS NOT NULL
  ),
  candidates AS (
    SELECT
      gf.id,
      gf.name,
      gf.lat,
      gf.lng,
      gf.geom,
      ss.base_description_similarity,
      gf.distance_from_bbox_center,
      (
        ss.base_description_similarity  -- Base similarity
        + CASE
            WHEN gf.distance_from_bbox_center IS NOT NULL THEN
              -- Geographic fit bonus: closer to bbox center = higher bonus
              v_geo_fit_max_weight * (1 - LEAST(gf.distance_from_bbox_center / v_distance_normalization, 1.0))
            ELSE 0.0
          END
      ) AS confidence
    FROM geographic_filtered gf
    JOIN semantic_scored ss ON ss.place_id = gf.id
  ),
  ranked_candidates AS (
    SELECT
      c.id,
      c.name,
      c.lat,
      c.lng,
      c.geom,
      c.base_description_similarity,
      c.distance_from_bbox_center,
      c.confidence
    FROM candidates c
    ORDER BY c.confidence DESC
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', rc.id,
          'name', rc.name,
          'lat', rc.lat,
          'lng', rc.lng,
          'geom_wkt', ST_AsText(rc.geom),
          'description_similarity', rc.base_description_similarity::FLOAT,
          'geographic_distance', rc.distance_from_bbox_center::FLOAT,
          'confidence', rc.confidence::FLOAT
        ) ORDER BY rc.confidence DESC
      ),
      '[]'::JSONB
    ) INTO v_result
  FROM ranked_candidates rc;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."get_candidates" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "game_logic"."get_candidates" ("session_id_param" "uuid") IS 'Orchestrates candidate filtering and applies business logic (SOLID architecture).

Pipeline:
1. filter_geographic_candidates(session_id) → places + distance_from_bbox_center
2. Extract place IDs from geographic results
3. filter_semantic_candidates(session_id, place_ids[]) → similarity scores
4. Join geographic + semantic results
5. Apply business logic: base similarity + geographic fit scoring

Scoring formula (business logic - ALL VALUES CONFIGURABLE via game_logic.config):
- Base: base_description_similarity
- Geographic fit: scoring.geographic_fit_max_weight * (1 - distance/scoring.distance_normalization)

Configuration (from game_logic.config):
- scoring.geographic_fit_max_weight (default 0.2): Maximum geographic fit bonus
- scoring.distance_normalization (default 20000000): Distance normalization (~20000km)

Filtering:
- Geographic: bbox inclusion/exclusion + wrong guess exclusion
- Semantic: base_description_similarity > semantic_similarity_threshold (default 0.5)
- NO LIMIT: Returns ALL candidates above threshold (count used by decide_next_turn)

Returns: JSONB array of ALL candidates above threshold, ordered by confidence DESC. Use jsonb_array_length() for count.
  Each candidate contains:
  - id, name, lat, lng: Basic place info
  - description_similarity: Raw base similarity (0-1)
  - geographic_distance: Distance in meters from bbox center (null if no bbox)
  - confidence: Final composite score with weights applied
Optimized: Returns JSONB directly to avoid repeated conversions.';
