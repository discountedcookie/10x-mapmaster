-- Function: get_candidates
-- Category: game
-- Purpose: Orchestrate candidate filtering and apply business logic (scoring weights)
-- Returns: JSONB with candidates array and count for efficient reuse
CREATE OR REPLACE FUNCTION "public"."get_candidates" ("session_id_param" "uuid") returns TABLE ("candidates" JSONB, "count" INT) language "plpgsql" AS $$
DECLARE
  v_trait_threshold FLOAT;
  v_affirmed_match_weight FLOAT;
  v_affirmed_mismatch_weight FLOAT;
  v_denied_match_weight FLOAT;
  v_denied_mismatch_weight FLOAT;
  v_geo_fit_max_weight FLOAT;
  v_distance_normalization FLOAT;
BEGIN
  -- Get scoring configuration from settings
  SELECT value::FLOAT INTO v_trait_threshold FROM app_settings WHERE key = 'trait_similarity_threshold';
  SELECT value::FLOAT INTO v_affirmed_match_weight FROM app_settings WHERE key = 'weight_affirmed_trait_match';
  SELECT value::FLOAT INTO v_affirmed_mismatch_weight FROM app_settings WHERE key = 'weight_affirmed_trait_mismatch';
  SELECT value::FLOAT INTO v_denied_match_weight FROM app_settings WHERE key = 'weight_denied_trait_match';
  SELECT value::FLOAT INTO v_denied_mismatch_weight FROM app_settings WHERE key = 'weight_denied_trait_mismatch';
  SELECT value::FLOAT INTO v_geo_fit_max_weight FROM app_settings WHERE key = 'weight_geographic_fit_max';
  SELECT value::FLOAT INTO v_distance_normalization FROM app_settings WHERE key = 'geographic_distance_normalization';
  
  -- Validate all settings are present
  IF v_trait_threshold IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: trait_similarity_threshold'; END IF;
  IF v_affirmed_match_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_affirmed_trait_match'; END IF;
  IF v_affirmed_mismatch_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_affirmed_trait_mismatch'; END IF;
  IF v_denied_match_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_denied_trait_match'; END IF;
  IF v_denied_mismatch_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_denied_trait_mismatch'; END IF;
  IF v_geo_fit_max_weight IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: weight_geographic_fit_max'; END IF;
  IF v_distance_normalization IS NULL THEN RAISE EXCEPTION 'Missing required app_setting: geographic_distance_normalization'; END IF;

  -- Orchestrate filtering and scoring pipeline
  RETURN QUERY
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
      gf.traits,
      ss.base_description_similarity,
      ss.affirmed_trait_similarity,
      ss.denied_trait_similarity,
      gf.distance_from_bbox_center,
      e.text AS description_text,
      (
        ss.base_description_similarity  -- Base similarity

        + CASE
            WHEN ss.affirmed_trait_similarity IS NOT NULL THEN
              -- Threshold-based weight: Does place HAVE affirmed trait?
              CASE
                WHEN ss.affirmed_trait_similarity > v_trait_threshold
                THEN v_affirmed_match_weight    -- Strong boost: place HAS affirmed trait
                ELSE v_affirmed_mismatch_weight -- Penalty: place doesn't have affirmed trait
              END
            ELSE 0.0
          END
        + CASE
            WHEN ss.denied_trait_similarity IS NOT NULL THEN
              -- Threshold-based weight: Does place HAVE denied trait?
              CASE
                WHEN ss.denied_trait_similarity > v_trait_threshold
                THEN v_denied_match_weight      -- Strong penalty: place HAS denied trait
                ELSE v_denied_mismatch_weight   -- Boost: place doesn't have denied trait
              END
            ELSE 0.0
          END
        + CASE
            WHEN gf.distance_from_bbox_center IS NOT NULL THEN
              -- Geographic fit bonus: closer to bbox center = higher bonus
              v_geo_fit_max_weight * (1 - LEAST(gf.distance_from_bbox_center / v_distance_normalization, 1.0))
            ELSE 0.0
          END
      ) AS confidence
    FROM geographic_filtered gf
    JOIN semantic_scored ss ON ss.place_id = gf.id
    JOIN embeddings e ON e.id = gf.embedding_id
  ),
  ranked_candidates AS (
    SELECT
      c.id,
      c.name,
      c.lat,
      c.lng,
      c.geom,
      c.traits,
      c.base_description_similarity,
      c.affirmed_trait_similarity,
      c.denied_trait_similarity,
      c.distance_from_bbox_center,
      c.description_text,
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
          'affirmed_trait_similarity', rc.affirmed_trait_similarity::FLOAT,
          'denied_trait_similarity', rc.denied_trait_similarity::FLOAT,
          'geographic_distance', rc.distance_from_bbox_center::FLOAT,
          'confidence', rc.confidence::FLOAT,
          'known_traits', COALESCE(SUBSTRING(rc.description_text FOR 300), '')
        ) ORDER BY rc.confidence DESC
      ),
      '[]'::JSONB
    ) AS candidates,
    (SELECT COUNT(*) FROM ranked_candidates)::INT AS count
  FROM ranked_candidates rc;
END;
$$;


ALTER FUNCTION "public"."get_candidates" ("session_id_param" "uuid") owner TO "postgres";


comment ON function "public"."get_candidates" ("session_id_param" "uuid") IS 'Orchestrates candidate filtering and applies business logic (SOLID architecture).

Pipeline:
1. filter_geographic_candidates(session_id) → places + distance_from_bbox_center
2. Extract place IDs from geographic results
3. filter_semantic_candidates(session_id, place_ids[]) → similarity scores
4. Join geographic + semantic results
5. Apply business logic: threshold-based weights + composite scoring

Scoring formula (business logic - ALL VALUES CONFIGURABLE via app_settings):
- Base: base_description_similarity
- Affirmed trait: weight_affirmed_trait_match if similarity > trait_similarity_threshold, else weight_affirmed_trait_mismatch
- Denied trait: weight_denied_trait_match if similarity > trait_similarity_threshold, else weight_denied_trait_mismatch
- Geographic fit: weight_geographic_fit_max * (1 - distance/geographic_distance_normalization)

Configuration (from app_settings):
- trait_similarity_threshold (default 0.6): Threshold to determine if place "has" trait
- weight_affirmed_trait_match (default 0.3): Boost when place HAS affirmed trait
- weight_affirmed_trait_mismatch (default -0.2): Penalty when place does NOT have affirmed trait
- weight_denied_trait_match (default -0.4): Penalty when place HAS denied trait
- weight_denied_trait_mismatch (default 0.1): Boost when place does NOT have denied trait
- weight_geographic_fit_max (default 0.2): Maximum geographic fit bonus
- geographic_distance_normalization (default 20000000): Distance normalization (~20000km)

Filtering:
- Geographic: bbox inclusion/exclusion + wrong guess exclusion
- Semantic: base_description_similarity > semantic_similarity_threshold (default 0.5)
- NO LIMIT: Returns ALL candidates above threshold (count used by decide_next_turn)

Returns: TABLE(candidates JSONB, count INT)
- candidates: JSONB array of ALL candidates above threshold, ordered by confidence DESC
  Each candidate contains:
  - id, name, lat, lng: Basic place info
  - description_similarity: Raw base similarity (0-1)
  - affirmed_trait_similarity: Raw similarity to affirmed traits (0-1, null if none)
  - denied_trait_similarity: Raw similarity to denied traits (0-1, null if none)
  - geographic_distance: Distance in meters from bbox center (null if no bbox)
  - confidence: Final composite score with weights applied
- count: Actual count of qualifying candidates (used to decide when to guess)

Optimized: Returns JSONB directly to avoid repeated conversions.';
