-- Function: filter_geographic_candidates
-- Category: game
-- Purpose: Apply geographic filters and calculate distance metrics
-- Returns: Places that pass geographic criteria + distance from region center
CREATE OR REPLACE FUNCTION "public"."filter_geographic_candidates" ("p_session_id" UUID) returns TABLE (
  id UUID,
  name TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  geom geometry,
  traits TEXT[],
  embedding_id UUID,
  distance_from_bbox_center DOUBLE PRECISION
) language "plpgsql" AS $$
DECLARE
  v_include_regions geometry[];
  v_exclude_regions geometry[];
BEGIN
  -- Get actual geometries from answered geographic questions
  SELECT ARRAY_AGG(gr.geom)
  INTO v_include_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = TRUE
    AND ga.geographic_region_id IS NOT NULL;

  SELECT ARRAY_AGG(gr.geom)
  INTO v_exclude_regions
  FROM game_answers ga
  JOIN geographic_regions gr ON gr.id = ga.geographic_region_id
  WHERE ga.session_id = p_session_id
    AND ga.answer = FALSE
    AND ga.geographic_region_id IS NOT NULL;

  -- Apply geographic filters and calculate distance metrics
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    p.geom,
    p.traits,
    p.embedding_id,
    -- Calculate distance from center of smallest (most specific) include region
    CASE 
      WHEN v_include_regions IS NOT NULL THEN
        (
          SELECT ST_Distance(
            p.geom::geography,
            ST_Centroid(region_geom)::geography
          )
          FROM UNNEST(v_include_regions) AS region_geom
          ORDER BY ST_Area(region_geom::geography) ASC
          LIMIT 1
        )
      ELSE NULL
    END AS distance_from_bbox_center
  FROM places p
  WHERE p.embedding_id IS NOT NULL
    AND p.geom IS NOT NULL
    -- Exclude wrong guesses
    AND NOT EXISTS (
      SELECT 1 FROM game_answers ga
      WHERE ga.session_id = p_session_id
        AND ga.place_id = p.id
        AND ga.trait_id IS NULL
        AND ga.geographic_region_id IS NULL
    )
    -- Include: Place must intersect with ALL include regions (AND logic)
    AND (
      v_include_regions IS NULL
      OR (
        SELECT COUNT(*)
        FROM UNNEST(v_include_regions) AS region_geom
        WHERE ST_Intersects(p.geom, region_geom)
      ) = array_length(v_include_regions, 1)
    )
    -- Exclude: Place must NOT intersect with ANY exclude region (OR logic)
    AND (
      v_exclude_regions IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM UNNEST(v_exclude_regions) AS region_geom
        WHERE ST_Intersects(p.geom, region_geom)
      )
    );
END;
$$;


ALTER FUNCTION "public"."filter_geographic_candidates" ("p_session_id" UUID) owner TO "postgres";


comment ON function "public"."filter_geographic_candidates" ("p_session_id" UUID) IS 'Filters places by geographic criteria using actual geometries and calculates distance metrics.

Uses ST_Intersects for accurate geometry-based filtering (works for Point, Polygon, MultiPolygon places).

Applies:
- Region inclusion (answered YES to geographic questions) - place must intersect ALL include regions
- Region exclusion (answered NO to geographic questions) - place must NOT intersect ANY exclude region
- Wrong guess exclusion (previously guessed incorrectly)

Calculates:
- distance_from_bbox_center: Distance (meters) from center of smallest include region

Returns: Places that pass geographic filters + distance metrics.

Called by: get_candidates() as first filtering step.';
