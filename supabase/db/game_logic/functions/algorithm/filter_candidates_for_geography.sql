-- Function: filter_candidates_for_geography
-- Category: algorithm
-- Schema: game_logic (internal - not client-accessible)
-- Purpose: Filter candidates based on geographic answer (YES = inside, NO = outside)
-- Spec: spec/algorithm.md#spatial-filtering
CREATE OR REPLACE FUNCTION "game_logic"."filter_candidates_for_geography" (
  p_candidates JSONB,
  p_geographic_region_id UUID,
  p_answer answer_value
) returns JSONB language plpgsql
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_region_geom geometry;
  v_candidate JSONB;
  v_place_geom geometry;
  v_is_inside BOOLEAN;
  v_result JSONB := '[]'::JSONB;
BEGIN
  -- Get region geometry
  SELECT geom INTO v_region_geom
  FROM geographic_regions
  WHERE id = p_geographic_region_id;
  
  IF v_region_geom IS NULL THEN
    RAISE EXCEPTION 'Geographic region % not found', p_geographic_region_id;
  END IF;
  
  -- Process each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    -- Parse geometry from WKT stored in candidate
    v_place_geom := ST_GeomFromText(v_candidate->>'geom_wkt', 4326);
    
    -- Check if place intersects with region
    v_is_inside := ST_Intersects(v_place_geom, v_region_geom);
    
    -- Per spec:
    -- YES answer → keep only candidates INSIDE the region
    -- NO answer → keep only candidates OUTSIDE the region
    -- NOT_SURE → keep all candidates (no filtering)
    IF p_answer = 'not_sure' THEN
      v_result := v_result || jsonb_build_array(v_candidate);
    ELSIF (p_answer = 'yes' AND v_is_inside) OR (p_answer = 'no' AND NOT v_is_inside) THEN
      v_result := v_result || jsonb_build_array(v_candidate);
    END IF;
  END LOOP;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION "game_logic"."filter_candidates_for_geography" (JSONB, UUID, answer_value) owner TO postgres;


comment ON function "game_logic"."filter_candidates_for_geography" (JSONB, UUID, answer_value) IS 'Filters candidates based on geographic answer.

Per spec (algorithm.md#spatial-filtering):
- Geographic Answer (YES): candidates = candidates.filter(ST_Contains(affirmed_region, place.geom))
- Geographic Answer (NO): candidates = candidates.filter(NOT ST_Contains(denied_region, place.geom))
- Geographic Answer (NOT_SURE): no filtering, keep all candidates

Uses ST_Intersects for proper geometry comparison (works with points, polygons, etc.)

Parameters:
- p_candidates: JSONB array of candidates with geom_wkt
- p_geographic_region_id: UUID of the geographic region
- p_answer: yes (inside), no (outside), not_sure (no filter)

Returns: Filtered JSONB array (candidates matching the geographic constraint)';
