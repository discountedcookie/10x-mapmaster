-- Function: apply_metadata_filter
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "public"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN DEFAULT TRUE
) returns BOOLEAN language "plpgsql" AS $$
DECLARE
  filter_type TEXT;
  property_paths JSONB;
  operator TEXT;
  value JSONB;
  property_value TEXT;
  path TEXT;
  result BOOLEAN := FALSE;
BEGIN
  filter_type := filter_config->>'filter_type';

  IF filter_type = 'string_in_list_check' THEN
    property_paths := filter_config->'property_paths';
    operator := filter_config->>'operator';
    value := filter_config->'value';

    FOREACH path IN ARRAY ARRAY(SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        IF operator = 'in' AND property_value = ANY(ARRAY(SELECT jsonb_array_elements_text(value))) THEN
          result := TRUE;
          EXIT;
        END IF;
      END IF;
    END LOOP;

  ELSIF filter_type = 'numeric_check' THEN
    property_paths := filter_config->'property_paths';
    operator := filter_config->>'operator';
    value := filter_config->'value';

    FOREACH path IN ARRAY ARRAY(SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        BEGIN
          IF operator = '>=' AND property_value::float >= (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '<=' AND property_value::float <= (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '>' AND property_value::float > (value->>0)::float THEN
            result := TRUE;
            EXIT;
          ELSIF operator = '<' AND property_value::float < (value->>0)::float THEN
            result := TRUE;
            EXIT;
          END IF;
        EXCEPTION WHEN invalid_text_representation THEN
          -- Property is not numeric, continue to next path
          CONTINUE;
        END;
      END IF;
    END LOOP;

  ELSIF filter_type = 'exists_check' THEN
    property_paths := filter_config->'property_paths';

    FOREACH path IN ARRAY (SELECT jsonb_array_elements_text(property_paths))
    LOOP
      property_value := descriptors#>>ARRAY[path];

      IF property_value IS NOT NULL THEN
        result := TRUE;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  RETURN result = answer;
END;
$$;


ALTER FUNCTION "public"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN
) owner TO "postgres";


comment ON function "public"."apply_metadata_filter" (
  "descriptors" "jsonb",
  "filter_config" "jsonb",
  "answer" BOOLEAN
) IS 'Applies metadata filters to place descriptors.
Parameters:
- descriptors: JSONB object containing place metadata
- filter_config: JSONB object defining filter type and parameters
- answer: expected result (TRUE for filter should pass, FALSE for inverted)

Returns TRUE if the filter condition matches the expected answer.';
