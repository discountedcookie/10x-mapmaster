-- Function: geo_region_for
-- Category: utilities
-- Purpose: Map geographic feature values to standard bounding boxes (SRID 4326)
-- Returns JSONB with bbox array [min_lat, max_lat, min_lng, max_lng]
CREATE OR REPLACE FUNCTION "public"."geo_region_for" ("p_feature_value" "text") returns "jsonb" language plpgsql security definer
SET
  search_path = public AS $$
DECLARE
  v_bbox JSONB;
BEGIN
  -- Map geographic feature values to standard bounding boxes
  -- Format: [min_lat, max_lat, min_lng, max_lng] in SRID 4326
  v_bbox := CASE LOWER(p_feature_value)
    -- Continents
    WHEN 'europe' THEN jsonb_build_object('bbox', jsonb_build_array(35, 71, -10, 40))
    WHEN 'asia' THEN jsonb_build_object('bbox', jsonb_build_array(-10, 77, 26, 180))
    WHEN 'americas' THEN jsonb_build_object('bbox', jsonb_build_array(-56, 85, -170, -35))
    WHEN 'africa' THEN jsonb_build_object('bbox', jsonb_build_array(-35, 37, -18, 52))
    WHEN 'oceania' THEN jsonb_build_object('bbox', jsonb_build_array(-47, -10, 113, 180))
    WHEN 'north america' THEN jsonb_build_object('bbox', jsonb_build_array(15, 85, -170, -50))
    WHEN 'south america' THEN jsonb_build_object('bbox', jsonb_build_array(-56, 13, -82, -35))
    
    -- European countries
    WHEN 'france' THEN jsonb_build_object('bbox', jsonb_build_array(41.5, 51.5, -8, 8))
    WHEN 'uk' THEN jsonb_build_object('bbox', jsonb_build_array(50, 59, -8, 2))
    WHEN 'united kingdom' THEN jsonb_build_object('bbox', jsonb_build_array(50, 59, -8, 2))
    WHEN 'germany' THEN jsonb_build_object('bbox', jsonb_build_array(47, 56, 6, 16))
    WHEN 'italy' THEN jsonb_build_object('bbox', jsonb_build_array(36, 47, 6, 19))
    WHEN 'spain' THEN jsonb_build_object('bbox', jsonb_build_array(36, 44, -10, 4))
    WHEN 'portugal' THEN jsonb_build_object('bbox', jsonb_build_array(37, 42, -10, -6))
    WHEN 'netherlands' THEN jsonb_build_object('bbox', jsonb_build_array(50.5, 53.5, 3, 8))
    WHEN 'belgium' THEN jsonb_build_object('bbox', jsonb_build_array(49.5, 51.5, 2, 6))
    WHEN 'switzerland' THEN jsonb_build_object('bbox', jsonb_build_array(45, 48, 5, 11))
    WHEN 'austria' THEN jsonb_build_object('bbox', jsonb_build_array(46.5, 49, 9, 17))
    WHEN 'czech republic' THEN jsonb_build_object('bbox', jsonb_build_array(48, 51, 12, 19))
    WHEN 'poland' THEN jsonb_build_object('bbox', jsonb_build_array(49, 54, 14, 24))
    WHEN 'sweden' THEN jsonb_build_object('bbox', jsonb_build_array(55, 70, 11, 25))
    WHEN 'norway' THEN jsonb_build_object('bbox', jsonb_build_array(58, 71, 4, 32))
    WHEN 'denmark' THEN jsonb_build_object('bbox', jsonb_build_array(54, 58, 8, 16))
    WHEN 'greece' THEN jsonb_build_object('bbox', jsonb_build_array(35, 42, 19, 29))
    WHEN 'hungary' THEN jsonb_build_object('bbox', jsonb_build_array(45.5, 48.5, 16, 23))
    WHEN 'romania' THEN jsonb_build_object('bbox', jsonb_build_array(43.5, 48.5, 20, 30))
    WHEN 'ireland' THEN jsonb_build_object('bbox', jsonb_build_array(51.5, 55.5, -11, -5))
    WHEN 'scotland' THEN jsonb_build_object('bbox', jsonb_build_array(55, 59, -8, -2))
    WHEN 'wales' THEN jsonb_build_object('bbox', jsonb_build_array(51.5, 53.5, -5, -2))
    WHEN 'england' THEN jsonb_build_object('bbox', jsonb_build_array(50, 56, -6, 2))
    
    -- Default: return NULL if feature value not recognized
    ELSE NULL
  END;

  RETURN v_bbox;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Error in geo_region_for: %', SQLERRM;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."geo_region_for" ("p_feature_value" "text") owner TO "postgres";


comment ON function "public"."geo_region_for" ("p_feature_value" "text") IS 'Maps geographic feature values to standard bounding boxes (SRID 4326).

Parameters:
- p_feature_value: Geographic feature value (e.g., "Europe", "France", "UK")

Returns JSONB object with bbox array:
{
  "bbox": [min_lat, max_lat, min_lng, max_lng]
}

Supported values:
- Continents: Europe, Asia, Americas, Africa, Oceania, North America, South America
- European countries: France, UK, Germany, Italy, Spain, Portugal, Netherlands, Belgium, 
  Switzerland, Austria, Czech Republic, Poland, Sweden, Norway, Denmark, Greece, Hungary, 
  Romania, Ireland, Scotland, Wales, England

Returns NULL if feature value not recognized.

Used by generate_question to set geographic_region when question_type=''geographic''.';
