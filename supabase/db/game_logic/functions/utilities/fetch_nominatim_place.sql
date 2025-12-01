-- Function: fetch_nominatim_place
-- Category: utilities
-- Purpose: Fetch place data from Nominatim by OSM ID
CREATE OR REPLACE FUNCTION "game_logic"."fetch_nominatim_place" ("p_osm_id" TEXT) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_status INT;
  v_content TEXT;
  v_osm_type TEXT;
  v_osm_id_num BIGINT;
  v_nominatim_data JSONB;
BEGIN
  -- ============================================================================
  -- PARSE OSM ID (format: "way/123456" or "node/123456" or "relation/123456")
  -- ============================================================================
  v_osm_type := split_part(p_osm_id, '/', 1);
  v_osm_id_num := split_part(p_osm_id, '/', 2)::BIGINT;
  
  IF v_osm_type NOT IN ('node', 'way', 'relation') THEN
    RAISE EXCEPTION 'Invalid OSM ID format. Expected node/way/relation prefix: %', p_osm_id;
  END IF;

  -- ============================================================================
  -- CALL NOMINATIM
  -- ============================================================================
  PERFORM set_config('statement_timeout', '60s', true);
  PERFORM extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '60000');
  PERFORM extensions.http_set_curlopt('CURLOPT_CONNECTTIMEOUT_MS', '15000');

  RAISE NOTICE 'Calling Nominatim lookup for: %', p_osm_id;

  SELECT status, content INTO v_status, v_content FROM extensions.http((
    'GET',
    format(
      'https://nominatim.openstreetmap.org/lookup?osm_ids=%s%s&format=json&extratags=1&addressdetails=1&namedetails=1&polygon_geojson=1',
      upper(left(v_osm_type, 1)),  -- N, W, or R
      v_osm_id_num
    ),
    ARRAY[
      extensions.http_header('User-Agent', '10x-mapmaster/1.0'),
      extensions.http_header('Accept', 'application/json')
    ],
    NULL,
    NULL
  )::extensions.http_request);

  IF v_status != 200 THEN
    RAISE EXCEPTION 'Nominatim lookup failed with status %: %', v_status, v_content;
  END IF;

  -- Parse response (returns array, take first result)
  v_nominatim_data := (v_content::jsonb)->0;
  
  IF v_nominatim_data IS NULL THEN
    RAISE EXCEPTION 'Place not found in Nominatim: %', p_osm_id;
  END IF;

  RETURN v_nominatim_data;
END;
$$;


ALTER FUNCTION "game_logic"."fetch_nominatim_place" (TEXT) owner TO "postgres";


comment ON function "game_logic"."fetch_nominatim_place" (TEXT) IS 'Fetch place data from Nominatim by OSM ID.

Parameters:
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364", "node/123456", "relation/789")

Returns: JSONB with Nominatim response including:
- name, display_name, lat, lon
- namedetails (localized names)
- address (country, city, etc.)
- extratags (height, wikipedia, etc.)
- geojson (geometry)

Raises exception if:
- Invalid OSM ID format
- Nominatim request fails
- Place not found';
