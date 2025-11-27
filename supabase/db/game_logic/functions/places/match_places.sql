-- Function: match_places
-- Category: places
-- Purpose: Find places matching query embedding with geographic filters
-- Uses embedding_id FK to embeddings table (not direct embedding column)
CREATE OR REPLACE FUNCTION "game_logic"."match_places" (
  "query_embedding" "extensions"."vector",
  "constraint_text" "text" DEFAULT NULL::"text",
  "filters" "jsonb" DEFAULT '{}'::"jsonb",
  "match_threshold" DOUBLE PRECISION DEFAULT 0.1,
  "match_count" INTEGER DEFAULT 20
) returns TABLE (
  "id" "uuid",
  "name" "text",
  "lat" DOUBLE PRECISION,
  "lng" DOUBLE PRECISION,
  "descriptors" "jsonb",
  "semantic_similarity" DOUBLE PRECISION,
  "spatial_confidence" DOUBLE PRECISION,
  "composite_confidence" DOUBLE PRECISION
) language "plpgsql"
SET
  search_path = public,
  game_logic,
  extensions AS $$
DECLARE
  centroid_geom geometry;
  max_distance float;
  spatial_score float;
  effective_embedding vector(384);
BEGIN
  effective_embedding := query_embedding;

  CREATE TEMP TABLE temp_candidates AS
  SELECT
    p.id,
    p.name,
    p.lat,
    p.lng,
    NULL::jsonb as descriptors,  -- places table doesn't have descriptors column
    p.geom,
    1 - (e.embedding <=> effective_embedding) as sem_similarity
  FROM places p
  JOIN embeddings e ON e.id = p.embedding_id
  WHERE p.embedding_id IS NOT NULL
    AND p.geom IS NOT NULL
    AND 1 - (e.embedding <=> effective_embedding) > match_threshold
    -- Apply geographic filters from filters parameter
    AND (
      filters IS NULL
      OR NOT (filters ? 'include_bbox')
      OR (
        filters->>'include_bbox' IS NULL
        OR ST_Within(
          p.geom,
          ST_MakeEnvelope(
            (filters->'include_bbox'->0)::text::float,
            (filters->'include_bbox'->1)::text::float,
            (filters->'include_bbox'->2)::text::float,
            (filters->'include_bbox'->3)::text::float,
            4326
          )
        )
      )
    )
    AND (
      filters IS NULL
      OR NOT (filters ? 'exclude_bbox')
      OR (
        filters->>'exclude_bbox' IS NULL
        OR NOT ST_Within(
          p.geom,
          ST_MakeEnvelope(
            (filters->'exclude_bbox'->0)::text::float,
            (filters->'exclude_bbox'->1)::text::float,
            (filters->'exclude_bbox'->2)::text::float,
            (filters->'exclude_bbox'->3)::text::float,
            4326
          )
        )
      )
    )
  ORDER BY e.embedding <=> effective_embedding, p.id
  LIMIT match_count;

  SELECT ST_Centroid(ST_Collect(geom)) INTO centroid_geom
  FROM temp_candidates;

  SELECT MAX(ST_Distance(geom::geography, centroid_geom::geography)) INTO max_distance
  FROM temp_candidates;

  IF max_distance IS NULL OR max_distance = 0 THEN
    spatial_score := 1.0;
  ELSIF max_distance <= 50000 THEN
    spatial_score := 1.0;
  ELSIF max_distance <= 200000 THEN
    spatial_score := 0.7 + (0.3 * (1 - (max_distance - 50000) / 150000));
  ELSIF max_distance <= 500000 THEN
    spatial_score := 0.3 + (0.4 * (1 - (max_distance - 200000) / 300000));
  ELSE
    spatial_score := 0.2 * (1 - LEAST((max_distance - 500000) / 5000000, 1));
  END IF;

  RETURN QUERY
  SELECT
    tc.id,
    tc.name,
    tc.lat,
    tc.lng,
    tc.descriptors,
    tc.sem_similarity::float as semantic_similarity,
    spatial_score::float as spatial_confidence,
    (tc.sem_similarity * 0.95 + spatial_score * 0.05)::float as composite_confidence
  FROM temp_candidates tc
  ORDER BY (tc.sem_similarity * 0.95 + spatial_score * 0.05) DESC, tc.id;

  DROP TABLE temp_candidates;
END;
$$;
