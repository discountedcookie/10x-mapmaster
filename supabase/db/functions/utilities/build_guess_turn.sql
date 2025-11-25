-- Function: build_guess_turn
-- Category: utilities
-- Purpose: Pure function to build guess next_turn JSONB (SRP)
CREATE OR REPLACE FUNCTION "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) returns JSONB language "plpgsql" immutable AS $$
BEGIN
  RETURN jsonb_build_object(
    'action', 'guess',
    'place_id', p_top_candidate->>'id',
    'place_name', p_top_candidate->>'name',
    'place_lat', (p_top_candidate->>'lat')::float,
    'place_lng', (p_top_candidate->>'lng')::float,
    'candidates', p_candidates
  );
END;
$$;


ALTER FUNCTION "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) owner TO "postgres";


comment ON function "public"."build_guess_turn" ("p_top_candidate" JSONB, "p_candidates" JSONB) IS 'Pure function to build guess next_turn JSONB.

IMMUTABLE: Same inputs always produce same output (no side effects).

Extracted from decide_next_turn for Single Responsibility Principle.';
