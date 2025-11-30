-- View: places_with_geometry
-- Schema: public
-- Description: Places with geometry as GeoJSON for map rendering
-- Note: Large geometries (>500 points) are simplified for performance
CREATE OR REPLACE VIEW "public"."places_with_geometry" AS
SELECT
  p.id,
  p.name,
  p.lat,
  p.lng,
  p.times_encountered,
  -- Simplify large geometries (cities) while keeping small ones (buildings) intact
  CASE
    WHEN extensions.ST_NPoints(p.geom) > 500 THEN
      extensions.ST_AsGeoJSON(extensions.ST_Simplify(p.geom, 0.001))::jsonb
    ELSE
      extensions.ST_AsGeoJSON(p.geom)::jsonb
  END AS geometry
FROM
  places p
WHERE
  p.lat IS NOT NULL
  AND p.lng IS NOT NULL
  AND p.pending_review = false;


ALTER VIEW "public"."places_with_geometry" OWNER TO "postgres";


-- Permissions: public read access
GRANT SELECT ON TABLE public.places_with_geometry TO anon;
GRANT SELECT ON TABLE public.places_with_geometry TO authenticated;
GRANT SELECT ON TABLE public.places_with_geometry TO service_role;
