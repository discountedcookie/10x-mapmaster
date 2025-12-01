-- Function: create_place_with_traits
-- Category: utilities
-- Purpose: Create a place record with traits and embedding from Nominatim data
CREATE OR REPLACE FUNCTION "game_logic"."create_place_with_traits" (
  "p_osm_id" TEXT,
  "p_nominatim_data" JSONB,
  "p_traits" JSONB,
  "p_is_curated" BOOLEAN DEFAULT FALSE
) returns UUID language plpgsql security definer
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  v_place_id UUID;
  v_name TEXT;
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
  v_geojson JSONB;
  v_trait_clauses TEXT[];
  v_combined_text TEXT;
  v_embedding_id UUID;
  v_trait_id TEXT;
  v_trait_clause TEXT;
  v_trait_embedding_id UUID;
BEGIN
  -- ============================================================================
  -- EXTRACT PLACE FIELDS
  -- ============================================================================
  v_name := COALESCE(
    p_nominatim_data->'namedetails'->>'name:en',
    p_nominatim_data->>'name',
    p_nominatim_data->>'display_name'
  );
  v_lat := (p_nominatim_data->>'lat')::DOUBLE PRECISION;
  v_lng := (p_nominatim_data->>'lon')::DOUBLE PRECISION;
  v_geojson := p_nominatim_data->'geojson';

  -- ============================================================================
  -- EXTRACT TRAIT CLAUSES FOR EMBEDDING
  -- ============================================================================
  IF p_traits IS NOT NULL AND jsonb_array_length(p_traits) > 0 THEN
    SELECT array_agg(DISTINCT t->>'clause')
    INTO v_trait_clauses
    FROM jsonb_array_elements(p_traits) AS t
    WHERE t->>'clause' IS NOT NULL;
  END IF;

  -- ============================================================================
  -- GENERATE EMBEDDING FROM COMBINED TRAIT CLAUSES
  -- ============================================================================
  IF v_trait_clauses IS NOT NULL AND array_length(v_trait_clauses, 1) > 0 THEN
    v_combined_text := array_to_string(v_trait_clauses, '. ');
    v_embedding_id := get_embedding(v_combined_text);
  END IF;

  -- ============================================================================
  -- CREATE PLACE RECORD
  -- ============================================================================
  -- Note: add_place expects p_pending_review, we invert p_is_curated
  -- Curated places (is_curated=TRUE) don't need review (pending_review=FALSE)
  v_place_id := game_logic.add_place(
    v_name,
    p_osm_id,
    v_lat::NUMERIC,
    v_lng::NUMERIC,
    v_geojson,
    NOT p_is_curated  -- invert: curated places don't need review
  );

  IF v_embedding_id IS NOT NULL THEN
    UPDATE places
    SET embedding_id = v_embedding_id
    WHERE id = v_place_id;
  END IF;

  -- ============================================================================
  -- CREATE TRAITS AND LINK TO PLACE
  -- ============================================================================
  IF p_traits IS NOT NULL AND jsonb_array_length(p_traits) > 0 THEN
    FOR v_trait_id, v_trait_clause IN
      SELECT DISTINCT t->>'id', t->>'clause'
      FROM jsonb_array_elements(p_traits) AS t
      WHERE t->>'id' IS NOT NULL AND t->>'clause' IS NOT NULL
    LOOP
      -- Generate embedding for trait clause and upsert trait
      v_trait_embedding_id := get_embedding(v_trait_clause);

      INSERT INTO traits (id, clause, embedding_id)
      VALUES (v_trait_id, v_trait_clause, v_trait_embedding_id)
      ON CONFLICT (id) DO UPDATE SET
        embedding_id = COALESCE(traits.embedding_id, EXCLUDED.embedding_id);

      -- Link trait to place
      INSERT INTO place_traits (place_id, trait_id)
      VALUES (v_place_id, v_trait_id)
      ON CONFLICT (place_id, trait_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN v_place_id;
END;
$$;


ALTER FUNCTION "game_logic"."create_place_with_traits" (TEXT, JSONB, JSONB, BOOLEAN) owner TO "postgres";


comment ON function "game_logic"."create_place_with_traits" (TEXT, JSONB, JSONB, BOOLEAN) IS 'Create a place record with traits and embedding.

Parameters:
- p_osm_id: OpenStreetMap ID (e.g., "way/5013364")
- p_nominatim_data: JSONB from fetch_nominatim_place()
- p_traits: JSONB array from extract_traits_from_nominatim()
- p_is_curated: Whether this is a curated place (default FALSE)

Process:
1. Extract name, lat, lng, geojson from Nominatim data
2. Generate embedding from combined trait clauses for place embedding
3. Create place record via add_place()
4. Generate embeddings for individual traits and link to place

Returns: UUID of created place';
