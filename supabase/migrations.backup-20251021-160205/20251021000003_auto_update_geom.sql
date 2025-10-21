-- Auto-populate geometry from lat/lng on INSERT/UPDATE
-- This ensures geom is always in sync with lat/lng coordinates

CREATE OR REPLACE FUNCTION update_geom_from_latlng()
RETURNS TRIGGER AS $$
BEGIN
  -- Automatically set geom from lat/lng when inserting or updating
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run before INSERT or UPDATE
CREATE TRIGGER places_update_geom
BEFORE INSERT OR UPDATE OF lat, lng ON places
FOR EACH ROW
EXECUTE FUNCTION update_geom_from_latlng();

COMMENT ON FUNCTION update_geom_from_latlng IS
'Automatically synchronizes the geom column with lat/lng coordinates.
Ensures spatial queries always work even when inserting places without explicit geom.';

-- Fix existing Golden Gate Bridge (if it exists) and any other places without geom
UPDATE places
SET geom = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
WHERE geom IS NULL AND lat IS NOT NULL AND lng IS NOT NULL;


