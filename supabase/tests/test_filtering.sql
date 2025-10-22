-- ============================================================================
-- Filtering System Tests
-- ============================================================================
-- Test both geographic and semantic filtering to verify dual-matching works

-- Test Setup: Get some test data
DO $$
DECLARE
  test_question_id UUID;
  test_embedding vector(384);
  europe_places UUID[];
  asia_places UUID[];
  all_place_ids UUID[];
  filtered_ids UUID[];
BEGIN
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'FILTERING SYSTEM TESTS';
  RAISE NOTICE '============================================================';

  -- Get all place IDs
  SELECT ARRAY_AGG(id) INTO all_place_ids FROM places;
  RAISE NOTICE 'Total places in database: %', array_length(all_place_ids, 1);

  -- ========================================================================
  -- TEST 1: Geographic Filtering - Europe (YES answer)
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 1: Geographic Filtering - "Is it in Europe?" = YES';
  RAISE NOTICE '--------------------------------------------------------';

  -- Get places actually in Europe by coordinates
  SELECT ARRAY_AGG(id) INTO europe_places
  FROM places
  WHERE ST_Contains(
    ST_MakeEnvelope(-10, 36, 40, 71, 4326),
    geom
  );

  RAISE NOTICE 'Places in Europe bounding box: %', array_length(europe_places, 1);
  RAISE NOTICE 'European places: %', (
    SELECT string_agg(name, ', ')
    FROM places
    WHERE id = ANY(europe_places)
  );

  -- Test the filter function
  SELECT ARRAY_AGG(id) INTO filtered_ids
  FROM filter_candidates_with_history(
    all_place_ids,
    '[{"question": "Is it in Europe?", "answer": true}]'::jsonb
  );

  RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);
  RAISE NOTICE 'Filtered places: %', (
    SELECT string_agg(name, ', ')
    FROM places
    WHERE id = ANY(filtered_ids)
  );

  -- Verify they match
  IF europe_places = filtered_ids OR
     (array_length(europe_places, 1) = array_length(filtered_ids, 1) AND
      europe_places @> filtered_ids AND filtered_ids @> europe_places) THEN
    RAISE NOTICE '✅ PASS: Filter matches expected results';
  ELSE
    RAISE NOTICE '❌ FAIL: Filter does not match expected results';
  END IF;

  -- ========================================================================
  -- TEST 2: Geographic Filtering - Europe (NO answer)
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 2: Geographic Filtering - "Is it in Europe?" = NO';
  RAISE NOTICE '--------------------------------------------------------';

  -- Get places NOT in Europe
  SELECT ARRAY_AGG(id) INTO europe_places
  FROM places
  WHERE NOT ST_Contains(
    ST_MakeEnvelope(-10, 36, 40, 71, 4326),
    geom
  );

  RAISE NOTICE 'Places NOT in Europe: %', array_length(europe_places, 1);

  -- Test the filter function
  SELECT ARRAY_AGG(id) INTO filtered_ids
  FROM filter_candidates_with_history(
    all_place_ids,
    '[{"question": "Is it in Europe?", "answer": false}]'::jsonb
  );

  RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);

  IF europe_places = filtered_ids OR
     (array_length(europe_places, 1) = array_length(filtered_ids, 1) AND
      europe_places @> filtered_ids AND filtered_ids @> europe_places) THEN
    RAISE NOTICE '✅ PASS: Filter matches expected results';
  ELSE
    RAISE NOTICE '❌ FAIL: Filter does not match expected results';
  END IF;

  -- ========================================================================
  -- TEST 3: Geographic Filtering - Asia (YES answer)
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 3: Geographic Filtering - "Is it in Asia?" = YES';
  RAISE NOTICE '--------------------------------------------------------';

  SELECT ARRAY_AGG(id) INTO asia_places
  FROM places
  WHERE ST_Contains(
    ST_MakeEnvelope(26, -10, 180, 77, 4326),
    geom
  );

  RAISE NOTICE 'Places in Asia bounding box: %', array_length(asia_places, 1);
  RAISE NOTICE 'Asian places: %', (
    SELECT string_agg(name, ', ')
    FROM places
    WHERE id = ANY(asia_places)
  );

  SELECT ARRAY_AGG(id) INTO filtered_ids
  FROM filter_candidates_with_history(
    all_place_ids,
    '[{"question": "Is it in Asia?", "answer": true}]'::jsonb
  );

  RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);

  IF asia_places = filtered_ids OR
     (array_length(asia_places, 1) = array_length(filtered_ids, 1) AND
      asia_places @> filtered_ids AND filtered_ids @> asia_places) THEN
    RAISE NOTICE '✅ PASS: Filter matches expected results';
  ELSE
    RAISE NOTICE '❌ FAIL: Filter does not match expected results';
  END IF;

  -- ========================================================================
  -- TEST 4: Cascading Geographic Filters
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 4: Cascading Filters - Europe=NO, then Asia=YES';
  RAISE NOTICE '--------------------------------------------------------';

  -- First filter: NOT in Europe
  SELECT ARRAY_AGG(id) INTO europe_places
  FROM places
  WHERE NOT ST_Contains(
    ST_MakeEnvelope(-10, 36, 40, 71, 4326),
    geom
  );

  -- Then filter: IS in Asia
  SELECT ARRAY_AGG(id) INTO asia_places
  FROM places
  WHERE id = ANY(europe_places)
    AND ST_Contains(
      ST_MakeEnvelope(26, -10, 180, 77, 4326),
      geom
    );

  RAISE NOTICE 'Expected: NOT Europe AND Asia = % places', array_length(asia_places, 1);

  SELECT ARRAY_AGG(id) INTO filtered_ids
  FROM filter_candidates_with_history(
    all_place_ids,
    '[
      {"question": "Is it in Europe?", "answer": false},
      {"question": "Is it in Asia?", "answer": true}
    ]'::jsonb
  );

  RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);
  RAISE NOTICE 'Resulting places: %', (
    SELECT string_agg(name, ', ')
    FROM places
    WHERE id = ANY(filtered_ids)
  );

  IF asia_places = filtered_ids OR
     (array_length(asia_places, 1) = array_length(filtered_ids, 1) AND
      asia_places @> filtered_ids AND filtered_ids @> asia_places) THEN
    RAISE NOTICE '✅ PASS: Cascading filter works correctly';
  ELSE
    RAISE NOTICE '❌ FAIL: Cascading filter incorrect';
  END IF;

  -- ========================================================================
  -- TEST 5: Semantic Filtering - Tall structures
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 5: Semantic Filtering - "Is it very tall?" = YES';
  RAISE NOTICE '--------------------------------------------------------';

  -- Get the question embedding
  SELECT embedding INTO test_embedding
  FROM questions
  WHERE text = 'Is it very tall (over 200 meters)?';

  IF test_embedding IS NULL THEN
    RAISE NOTICE '⚠️  SKIP: Question has no embedding';
  ELSE
    -- Get places with high similarity (>0.4)
    SELECT ARRAY_AGG(id) INTO europe_places
    FROM places
    WHERE embedding IS NOT NULL
      AND (1 - (embedding <=> test_embedding)) > 0.4;

    RAISE NOTICE 'Places with similarity > 0.4: %', array_length(europe_places, 1);
    RAISE NOTICE 'Similar places: %', (
      SELECT string_agg(name || ' (' || ROUND((1 - (embedding <=> test_embedding))::numeric, 2) || ')', ', ')
      FROM places
      WHERE id = ANY(europe_places)
    );

    SELECT ARRAY_AGG(id) INTO filtered_ids
    FROM filter_candidates_with_history(
      all_place_ids,
      '[{"question": "Is it very tall (over 200 meters)?", "answer": true}]'::jsonb
    );

    RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);

    IF europe_places = filtered_ids OR
       (array_length(europe_places, 1) = array_length(filtered_ids, 1) AND
        europe_places @> filtered_ids AND filtered_ids @> europe_places) THEN
      RAISE NOTICE '✅ PASS: Semantic filter matches expected results';
    ELSE
      RAISE NOTICE '❌ FAIL: Semantic filter does not match';
    END IF;
  END IF;

  -- ========================================================================
  -- TEST 6: Mixed Geographic + Semantic
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 6: Mixed Filter - Europe=YES AND Tall=YES';
  RAISE NOTICE '--------------------------------------------------------';

  SELECT embedding INTO test_embedding
  FROM questions
  WHERE text = 'Is it very tall (over 200 meters)?';

  IF test_embedding IS NULL THEN
    RAISE NOTICE '⚠️  SKIP: Question has no embedding';
  ELSE
    -- First geographic: in Europe
    SELECT ARRAY_AGG(id) INTO europe_places
    FROM places
    WHERE ST_Contains(
      ST_MakeEnvelope(-10, 36, 40, 71, 4326),
      geom
    );

    -- Then semantic: tall
    SELECT ARRAY_AGG(id) INTO asia_places
    FROM places
    WHERE id = ANY(europe_places)
      AND embedding IS NOT NULL
      AND (1 - (embedding <=> test_embedding)) > 0.4;

    RAISE NOTICE 'Expected: Europe AND Tall = % places', array_length(asia_places, 1);
    RAISE NOTICE 'Expected places: %', (
      SELECT string_agg(name, ', ')
      FROM places
      WHERE id = ANY(asia_places)
    );

    SELECT ARRAY_AGG(id) INTO filtered_ids
    FROM filter_candidates_with_history(
      all_place_ids,
      '[
        {"question": "Is it in Europe?", "answer": true},
        {"question": "Is it very tall (over 200 meters)?", "answer": true}
      ]'::jsonb
    );

    RAISE NOTICE 'Filter function returned: % places', array_length(filtered_ids, 1);
    RAISE NOTICE 'Resulting places: %', (
      SELECT string_agg(name, ', ')
      FROM places
      WHERE id = ANY(filtered_ids)
    );

    IF asia_places = filtered_ids OR
       (array_length(asia_places, 1) = array_length(filtered_ids, 1) AND
        asia_places @> filtered_ids AND filtered_ids @> asia_places) THEN
      RAISE NOTICE '✅ PASS: Mixed filter works correctly';
    ELSE
      RAISE NOTICE '❌ FAIL: Mixed filter incorrect';
    END IF;
  END IF;

  -- ========================================================================
  -- TEST 7: Edge Case - Empty result set
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 7: Edge Case - Contradictory filters';
  RAISE NOTICE '--------------------------------------------------------';

  SELECT ARRAY_AGG(id) INTO filtered_ids
  FROM filter_candidates_with_history(
    all_place_ids,
    '[
      {"question": "Is it in Europe?", "answer": true},
      {"question": "Is it in Asia?", "answer": true}
    ]'::jsonb
  );

  IF filtered_ids IS NULL OR array_length(filtered_ids, 1) IS NULL OR array_length(filtered_ids, 1) = 0 THEN
    RAISE NOTICE '✅ PASS: Contradictory filters return empty set';
  ELSE
    RAISE NOTICE '❌ FAIL: Should return empty set, got % places', array_length(filtered_ids, 1);
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'TESTS COMPLETE';
  RAISE NOTICE '============================================================';
END $$;
