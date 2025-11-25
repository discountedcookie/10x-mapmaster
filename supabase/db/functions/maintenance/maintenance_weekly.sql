-- Function: maintenance_weekly
-- Category: maintenance
-- TODO: Update for trait-based system
CREATE OR REPLACE FUNCTION "public"."maintenance_weekly" () returns TABLE (
  "questions_duplicates_removed" INTEGER,
  "questions_kept" INTEGER,
  "places_duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer AS $$
DECLARE
  v_places_result RECORD;
BEGIN
  -- Run place deduplication
  SELECT * INTO v_places_result FROM deduplicate_places();

  RETURN QUERY SELECT
    0::INTEGER, -- questions deduplication removed for now
    0::INTEGER,
    v_places_result.duplicates_removed,
    v_places_result.places_kept;
END;
$$;


ALTER FUNCTION "public"."maintenance_weekly" () owner TO "postgres";
