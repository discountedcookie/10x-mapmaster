-- Function: approve_pending_place
-- Category: places
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."approve_pending_place" ("p_place_id" "uuid") returns "jsonb" language "plpgsql" security definer AS $$
DECLARE
  v_place RECORD;
BEGIN
  -- Get place
  SELECT * INTO v_place FROM places WHERE id = p_place_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Place not found: %', p_place_id;
  END IF;

  IF NOT v_place.pending_review THEN
    RETURN jsonb_build_object('status', 'already_approved', 'place_id', p_place_id);
  END IF;

  -- Approve
  UPDATE places
  SET pending_review = FALSE
  WHERE id = p_place_id;

  -- Trigger will fire for enrichment

  RETURN jsonb_build_object('status', 'approved', 'place_id', p_place_id);
END;
$$;


ALTER FUNCTION "public"."approve_pending_place" ("p_place_id" "uuid") owner TO "postgres";


comment ON function "public"."approve_pending_place" ("p_place_id" "uuid") IS 'Admin function to approve pending places submitted by anonymous users.';
