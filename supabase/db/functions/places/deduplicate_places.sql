-- Function: deduplicate_places
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."deduplicate_places" () returns TABLE (
  "duplicates_removed" INTEGER,
  "places_kept" INTEGER
) language "plpgsql" security definer
SET
  "search_path" TO 'public' AS $$
DECLARE
  v_duplicates_removed INTEGER := 0;
  v_places_kept INTEGER := 0;
  v_place_record RECORD;
  v_similar_places UUID[];
  v_best_place_id UUID;
  v_total_times_encountered INTEGER;
  v_avg_confidence FLOAT;
  v_combined_descriptors JSONB;
BEGIN
  -- Find places with same nominatim_place_id (exact duplicates)
  FOR v_place_record IN
    SELECT
      p1.nominatim_place_id,
      array_agg(p1.id ORDER BY p1.times_encountered DESC, p1.created_at ASC) as place_ids
    FROM places p1
    WHERE p1.nominatim_place_id IS NOT NULL
      AND p1.pending_review = false
    GROUP BY p1.nominatim_place_id
    HAVING COUNT(*) > 1
  LOOP
    -- Keep the first place, merge others into it
    v_best_place_id := v_place_record.place_ids[1];
    v_similar_places := v_place_record.place_ids[2:array_length(v_place_record.place_ids, 1)];

    -- Calculate merged stats
    SELECT
      SUM(times_encountered),
      jsonb_object_agg(COALESCE(descriptors->>'key', ''), descriptors->>'value')
    INTO v_total_times_encountered, v_combined_descriptors
    FROM places
    WHERE id = ANY(v_similar_places || ARRAY[v_best_place_id]);

    -- Update the best place with merged stats
    UPDATE places
    SET
      times_encountered = v_total_times_encountered,
      descriptors = v_combined_descriptors,
      updated_at = NOW()
    WHERE id = v_best_place_id;

    -- Update game_sessions to point to the kept place
    UPDATE game_sessions
    SET place_id = v_best_place_id
    WHERE place_id = ANY(v_similar_places);

    -- Delete duplicates
    DELETE FROM places
    WHERE id = ANY(v_similar_places);

    v_duplicates_removed := v_duplicates_removed + array_length(v_similar_places, 1);
    v_places_kept := v_places_kept + 1;
  END LOOP;

  -- Find nearby places with similar names (within 100m, name similarity > 0.8)
  FOR v_place_record IN
    SELECT
      p1.id as place_id,
      p1.name as place_name,
      p1.lat,
      p1.lng,
      array_agg(p2.id) as similar_ids
    FROM places p1
    JOIN places p2 ON p1.id != p2.id
      AND ST_DWithin(p1.geom, p2.geom, 100)  -- Within 100 meters
      AND similarity(p1.name, p2.name) > 0.8  -- Name similarity > 80%
      AND p1.pending_review = false
      AND p2.pending_review = false
    WHERE p1.id < p2.id  -- Avoid duplicate pairs
    GROUP BY p1.id, p1.name, p1.lat, p1.lng
  LOOP
    -- Keep the place with more encounters, merge others
    SELECT id INTO v_best_place_id
    FROM places
    WHERE id = ANY(array_append(v_place_record.similar_ids, v_place_record.place_id))
    ORDER BY times_encountered DESC, created_at ASC
    LIMIT 1;

    v_similar_places := ARRAY[v_place_record.place_id] || v_place_record.similar_ids;
    v_similar_places := array_remove(v_similar_places, v_best_place_id);

    -- Calculate merged stats
    SELECT
      SUM(times_encountered),
      jsonb_object_agg(COALESCE(descriptors->>'key', ''), descriptors->>'value')
    INTO v_total_times_encountered, v_combined_descriptors
    FROM places
    WHERE id = ANY(v_similar_places || ARRAY[v_best_place_id]);

    -- Update the best place with merged stats
    UPDATE places
    SET
      times_encountered = v_total_times_encountered,
      descriptors = v_combined_descriptors,
      updated_at = NOW()
    WHERE id = v_best_place_id;

    -- Update game_sessions to point to the kept place
    UPDATE game_sessions
    SET place_id = v_best_place_id
    WHERE place_id = ANY(v_similar_places);

    -- Delete duplicates
    DELETE FROM places
    WHERE id = ANY(v_similar_places);

    v_duplicates_removed := v_duplicates_removed + array_length(v_similar_places, 1);
    v_places_kept := v_places_kept + 1;
  END LOOP;

  RETURN QUERY SELECT v_duplicates_removed, v_places_kept;
END;
$$;


ALTER FUNCTION "public"."deduplicate_places" () owner TO "postgres";
