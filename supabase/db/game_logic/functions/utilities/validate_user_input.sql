-- Function: validate_user_input
-- Category: utilities
-- Dependencies: See migration files for full dependency chain
-- This file is auto-generated from migrations
CREATE OR REPLACE FUNCTION "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text" DEFAULT 'input'
) returns "text" language "plpgsql" security definer
SET
  search_path = public,
  game_logic AS $$
DECLARE
  trimmed_input TEXT;
BEGIN
  -- NULL check
  IF p_input IS NULL THEN
    RAISE EXCEPTION 'Invalid input: % cannot be null', p_field_name;
  END IF;

  -- Trim whitespace
  trimmed_input := trim(p_input);

  -- Empty string check (after trim)
  IF length(trimmed_input) = 0 THEN
    RAISE EXCEPTION 'Invalid input: % cannot be empty', p_field_name;
  END IF;

  -- Length validation
  IF length(p_input) > p_max_length THEN
    RAISE EXCEPTION 'Invalid input: % exceeds maximum length of % characters', p_field_name, p_max_length;
  END IF;

  -- Control character detection (reject ASCII 0-31 except tab/newline/CR)
  -- ASCII 9 = tab, 10 = newline, 13 = carriage return
  -- Note: \x00 (null byte) is already caught by this regex
  IF p_input ~ '[\x00-\x08\x0B\x0C\x0E-\x1F]' THEN
    RAISE EXCEPTION 'Invalid input: % contains forbidden control characters', p_field_name;
  END IF;

  -- Excessive newlines detection (3+ consecutive)
  IF p_input ~ '(\r?\n){3,}' THEN
    RAISE EXCEPTION 'Invalid input: % contains excessive consecutive newlines', p_field_name;
  END IF;

  RETURN trimmed_input;
END;
$$;


ALTER FUNCTION "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text"
) owner TO "postgres";


comment ON function "game_logic"."validate_user_input" (
  "p_input" "text",
  "p_max_length" INTEGER,
  "p_field_name" "text"
) IS 'Validates user input for security and data integrity.
Checks:
- NULL values
- Empty strings (after trim)
- Length limits
- Control characters (rejects ASCII 0-31 except tab/newline/CR, includes null bytes)
- Excessive consecutive newlines (3+)

Returns trimmed input if valid, raises exception otherwise.';
