-- Function: add_place
-- Category: places
-- Adds a place to the database with geometry from Nominatim (Point, Polygon, or MultiPolygon)
CREATE OR REPLACE FUNCTION "game_logic"."add_place" (
  p_name TEXT,
  p_osm_id TEXT,
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL,
  p_geojson JSONB DEFAULT NULL,
  p_pending_review BOOLEAN DEFAULT FALSE
) returns UUID language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place_id uuid;
  v_geom geometry;
  v_lat NUMERIC;
  v_lng NUMERIC;
BEGIN
  -- Validate name
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'INVALID_NAME: Place name cannot be empty';
  END IF;

  -- Validate osm_id
  IF p_osm_id IS NULL OR trim(p_osm_id) = '' THEN
    RAISE EXCEPTION 'INVALID_OSM_ID: OSM ID cannot be empty';
  END IF;

  -- Handle geometry: prefer geojson, fallback to lat/lng point
  IF p_geojson IS NOT NULL THEN
    -- Convert GeoJSON to PostGIS geometry (Point, Polygon, or MultiPolygon)
    v_geom := ST_SetSRID(ST_GeomFromGeoJSON(p_geojson::text), 4326);
    
    -- Calculate lat/lng from centroid if not provided
    IF p_lat IS NULL OR p_lng IS NULL THEN
      v_lat := ST_Y(ST_Centroid(v_geom));
      v_lng := ST_X(ST_Centroid(v_geom));
    ELSE
      v_lat := p_lat;
      v_lng := p_lng;
    END IF;
  ELSIF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    -- Fallback: create Point geometry from lat/lng
    IF p_lat < -90 OR p_lat > 90 THEN
      RAISE EXCEPTION 'INVALID_LATITUDE: Latitude must be between -90 and 90';
    END IF;
    IF p_lng < -180 OR p_lng > 180 THEN
      RAISE EXCEPTION 'INVALID_LONGITUDE: Longitude must be between -180 and 180';
    END IF;
    
    v_geom := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
    v_lat := p_lat;
    v_lng := p_lng;
  ELSE
    RAISE EXCEPTION 'INVALID_GEOMETRY: Must provide either geojson or lat/lng';
  END IF;

  -- Insert place
  INSERT INTO places (
    name,
    osm_id,
    lat,
    lng,
    geom,
    pending_review
  )
  VALUES (
    p_name,
    p_osm_id,
    v_lat,
    v_lng,
    v_geom,
    p_pending_review
  )
  ON CONFLICT (osm_id) DO UPDATE SET
    name = EXCLUDED.name,
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    geom = EXCLUDED.geom,
    pending_review = EXCLUDED.pending_review,
    updated_at = NOW()
  RETURNING id INTO v_place_id;

  RETURN v_place_id;
END;
$$;


ALTER FUNCTION "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) owner TO postgres;


GRANT
EXECUTE ON function "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) TO authenticated,
anon;


comment ON function "game_logic"."add_place" (TEXT, TEXT, NUMERIC, NUMERIC, JSONB, BOOLEAN) IS 'Adds a place to the database with geometry from Nominatim.

Parameters:
- p_name: Place name
- p_osm_id: OpenStreetMap ID (unique)
- p_lat: Latitude (optional if geojson provided)
- p_lng: Longitude (optional if geojson provided)
- p_geojson: GeoJSON geometry from Nominatim (Point, Polygon, or MultiPolygon)
- p_pending_review: Whether place needs review before being active

Geometry handling:
- If geojson provided: uses actual geometry, calculates lat/lng from centroid if needed
- If only lat/lng provided: creates Point geometry
- Supports upsert on osm_id conflict

Returns: place_id (UUID)';
