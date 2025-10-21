-- Enable PostGIS extension for geographic queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geometry column for spatial queries (Point with WGS84 coordinate system)
ALTER TABLE places ADD COLUMN IF NOT EXISTS geom geometry(Point, 4326);

-- Populate geometry from existing lat/lng
UPDATE places
SET geom = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
WHERE geom IS NULL;

-- Create spatial index for efficient geographic queries
CREATE INDEX IF NOT EXISTS idx_places_geom ON places USING GIST (geom);

-- Add comment explaining the geometry column
COMMENT ON COLUMN places.geom IS 'Geographic point for spatial queries. Automatically synced with lat/lng.';
