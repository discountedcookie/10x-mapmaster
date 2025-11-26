-- Function: filter_candidates_by_geography
-- Category: algorithm
-- Purpose: Filter candidates via PostGIS for geographic YES/NO answers
-- Spec: openspec/specs/algorithm/spec.md#spatial-filtering
CREATE OR REPLACE FUNCTION filter_candidates_by_geography (
  p_candidates JSONB,
  p_region_id UUID,
  p_answer TEXT -- 'yes' or 'no'
) returns JSONB language plpgsql AS $$
DECLARE
  v_region_geom geometry;
  v_filtered JSONB := '[]'::JSONB;
  v_candidate JSONB;
  v_place_geom geometry;
  v_contains BOOLEAN;
BEGIN
  -- Get region geometry
  SELECT geom INTO v_region_geom
  FROM geographic_regions
  WHERE id = p_region_id;
  
  IF v_region_geom IS NULL THEN
    RAISE EXCEPTION 'Geographic region % not found', p_region_id;
  END IF;
  
  -- Filter each candidate
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates)
  LOOP
    -- Get place geometry
    SELECT geom INTO v_place_geom
    FROM places
    WHERE id = (v_candidate->>'id')::UUID;
    
    IF v_place_geom IS NOT NULL THEN
      -- Check if region contains place
      v_contains := ST_Contains(v_region_geom, v_place_geom);
      
      -- YES answer: keep places IN the region
      -- NO answer: keep places NOT IN the region
      IF (p_answer = 'yes' AND v_contains) OR (p_answer = 'no' AND NOT v_contains) THEN
        v_filtered := v_filtered || v_candidate;
      END IF;
    END IF;
  END LOOP;
  
  RETURN v_filtered;
END;
$$;


ALTER FUNCTION filter_candidates_by_geography (JSONB, UUID, TEXT) owner TO postgres;


comment ON function filter_candidates_by_geography (JSONB, UUID, TEXT) IS 'Filters candidates via PostGIS for geographic answers.

Geographic YES answer:
- candidates = filter(ST_Contains(region, place.geom))

Geographic NO answer:  
- candidates = filter(NOT ST_Contains(region, place.geom))

Parameters:
- p_candidates: JSONB array of candidates with id field
- p_region_id: Geographic region UUID
- p_answer: ''yes'' or ''no''

Returns: Filtered JSONB array of candidates';
