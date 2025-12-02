-- Function: extract_traits_from_nominatim
-- Category: utilities
-- Purpose: Extract basic traits from Nominatim data (rule-based only)
CREATE OR REPLACE FUNCTION "game_logic"."extract_traits_from_nominatim" ("p_nominatim_data" JSONB) returns JSONB language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_traits JSONB := '[]'::jsonb;
  v_address JSONB;
BEGIN
  v_address := COALESCE(p_nominatim_data->'address', '{}'::jsonb);

  -- Add class as trait
  IF p_nominatim_data->>'class' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'class:' || lower(p_nominatim_data->>'class'),
      'clause', initcap(p_nominatim_data->>'class')
    ));
  END IF;
  
  -- Add type as trait
  IF p_nominatim_data->>'type' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'type:' || lower(p_nominatim_data->>'type'),
      'clause', initcap(replace(p_nominatim_data->>'type', '_', ' '))
    ));
  END IF;

  -- Add country as trait
  IF v_address->>'country' IS NOT NULL THEN
    v_traits := v_traits || jsonb_build_array(jsonb_build_object(
      'id', 'country:' || lower(replace(v_address->>'country', ' ', '_')),
      'clause', v_address->>'country'
    ));
  END IF;

  RETURN v_traits;
END;
$$;


ALTER FUNCTION "game_logic"."extract_traits_from_nominatim" (JSONB) owner TO "postgres";


comment ON function "game_logic"."extract_traits_from_nominatim" (JSONB) IS 'Extract basic traits from Nominatim data (rule-based only).

Returns class, type, and country as initial traits.
LLM-based trait extraction is handled by update_place_traits().';
