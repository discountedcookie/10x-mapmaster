-- ============================================================================
-- Test: "One of the tallest mountains" Description
-- ============================================================================
-- This test reproduces the issue where Mount Fuji is not being suggested
-- after Everest is rejected

DO $$
DECLARE
  test_description TEXT := 'One of the tallest mountains';
  test_embedding vector(384);
  fuji_id UUID;
  everest_id UUID;
  all_place_ids UUID[];
  initial_candidates UUID[];
  after_everest_no UUID[];
  similarity_threshold FLOAT := 0.4;
BEGIN
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'TEST: "One of the tallest mountains" - Fuji Missing Bug';
  RAISE NOTICE '============================================================';
  RAISE NOTICE '';

  -- Get Mount Fuji and Everest IDs
  SELECT id INTO fuji_id FROM places WHERE name = 'Mount Fuji';
  SELECT id INTO everest_id FROM places WHERE name = 'Mount Everest';

  RAISE NOTICE 'Mount Fuji ID: %', fuji_id;
  RAISE NOTICE 'Mount Everest ID: %', everest_id;
  RAISE NOTICE '';

  -- ========================================================================
  -- STEP 1: Generate embedding for user description
  -- ========================================================================
  RAISE NOTICE 'STEP 1: Testing initial candidate selection';
  RAISE NOTICE '--------------------------------------------------------';

  -- In production, this would come from generate-embedding function
  -- For testing, we'll use a dummy embedding and check actual place embeddings
  SELECT embedding INTO test_embedding FROM places WHERE name = 'Mount Everest';

  -- Get all places
  SELECT ARRAY_AGG(id) INTO all_place_ids FROM places;
  RAISE NOTICE 'Total places in database: %', array_length(all_place_ids, 1);

  -- Check similarity scores for all places (simulating initial candidate selection)
  RAISE NOTICE '';
  RAISE NOTICE 'Similarity scores for "tallest mountains" (using Everest embedding as proxy):';
  RAISE NOTICE '--------------------------------------------------------';

  PERFORM
  FROM (
    SELECT
      name,
      ROUND((1 - (embedding <=> test_embedding))::numeric, 3) as similarity,
      CASE
        WHEN (1 - (embedding <=> test_embedding)) >= similarity_threshold THEN '✅ INCLUDED'
        ELSE '❌ EXCLUDED'
      END as status
    FROM places
    WHERE embedding IS NOT NULL
    ORDER BY similarity DESC
    LIMIT 10
  ) ranked
  WHERE RAISE_NOTICE('%: % %', ranked.name, ranked.similarity, ranked.status) IS NOT NULL;

  -- Get initial candidates (similarity >= 0.4)
  SELECT ARRAY_AGG(id) INTO initial_candidates
  FROM places
  WHERE embedding IS NOT NULL
    AND (1 - (embedding <=> test_embedding)) >= similarity_threshold;

  RAISE NOTICE '';
  RAISE NOTICE 'Initial candidates (similarity >= %): % places', similarity_threshold, array_length(initial_candidates, 1);
  RAISE NOTICE 'Candidates: %', (
    SELECT string_agg(name, ', ')
    FROM places
    WHERE id = ANY(initial_candidates)
  );

  -- Check if both mountains are in initial candidates
  IF fuji_id = ANY(initial_candidates) THEN
    RAISE NOTICE '✅ Mount Fuji IS in initial candidates';
  ELSE
    RAISE NOTICE '❌ Mount Fuji NOT in initial candidates';
  END IF;

  IF everest_id = ANY(initial_candidates) THEN
    RAISE NOTICE '✅ Mount Everest IS in initial candidates';
  ELSE
    RAISE NOTICE '❌ Mount Everest NOT in initial candidates';
  END IF;

  -- ========================================================================
  -- STEP 2: Test semantic filtering with "Is it very tall?" = NO
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 2: After answering "Is it very tall?" = NO';
  RAISE NOTICE '--------------------------------------------------------';

  -- Simulate the filter after user says NO to "Is it very tall?"
  SELECT ARRAY_AGG(id) INTO after_everest_no
  FROM filter_candidates_with_history(
    initial_candidates,
    '[{"question": "Is it very tall (over 200 meters)?", "answer": false}]'::jsonb
  );

  RAISE NOTICE 'Remaining candidates after "tall" = NO: % places', COALESCE(array_length(after_everest_no, 1), 0);

  IF after_everest_no IS NOT NULL AND array_length(after_everest_no, 1) > 0 THEN
    RAISE NOTICE 'Remaining: %', (
      SELECT string_agg(name, ', ')
      FROM places
      WHERE id = ANY(after_everest_no)
    );
  ELSE
    RAISE NOTICE 'Remaining: NONE';
  END IF;

  -- Check if Fuji survived
  IF after_everest_no IS NOT NULL AND fuji_id = ANY(after_everest_no) THEN
    RAISE NOTICE '✅ Mount Fuji SURVIVED the filter';
  ELSE
    RAISE NOTICE '❌ Mount Fuji was FILTERED OUT';
  END IF;

  -- ========================================================================
  -- STEP 3: Check the "tall" question embedding similarity
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 3: Analyzing "Is it very tall?" question';
  RAISE NOTICE '--------------------------------------------------------';

  DECLARE
    tall_question_embedding vector(384);
    fuji_tall_similarity FLOAT;
    everest_tall_similarity FLOAT;
  BEGIN
    SELECT embedding INTO tall_question_embedding
    FROM questions
    WHERE text = 'Is it very tall (over 200 meters)?';

    IF tall_question_embedding IS NULL THEN
      RAISE NOTICE '⚠️  "Is it very tall?" question has NO embedding!';
    ELSE
      -- Check similarity of Fuji and Everest to "tall" question
      SELECT (1 - (embedding <=> tall_question_embedding)) INTO fuji_tall_similarity
      FROM places WHERE id = fuji_id;

      SELECT (1 - (embedding <=> tall_question_embedding)) INTO everest_tall_similarity
      FROM places WHERE id = everest_id;

      RAISE NOTICE 'Mount Fuji similarity to "very tall": % (threshold: 0.4)', ROUND(fuji_tall_similarity::numeric, 3);
      RAISE NOTICE 'Mount Everest similarity to "very tall": % (threshold: 0.4)', ROUND(everest_tall_similarity::numeric, 3);

      IF fuji_tall_similarity > 0.4 THEN
        RAISE NOTICE '❌ PROBLEM: Fuji similarity > 0.4 means answering NO will EXCLUDE it!';
      ELSE
        RAISE NOTICE '✅ Fuji similarity < 0.4 means answering NO will KEEP it';
      END IF;

      IF everest_tall_similarity > 0.4 THEN
        RAISE NOTICE '✅ Everest similarity > 0.4 means answering NO will EXCLUDE it';
      ELSE
        RAISE NOTICE '❌ Everest similarity < 0.4 means answering NO will KEEP it';
      END IF;
    END IF;
  END;

  -- ========================================================================
  -- STEP 4: Check place embeddings content
  -- ========================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 4: Examining place descriptors';
  RAISE NOTICE '--------------------------------------------------------';

  DECLARE
    fuji_descriptors JSONB;
    everest_descriptors JSONB;
  BEGIN
    SELECT descriptors INTO fuji_descriptors FROM places WHERE id = fuji_id;
    SELECT descriptors INTO everest_descriptors FROM places WHERE id = everest_id;

    RAISE NOTICE 'Mount Fuji descriptors: %', fuji_descriptors;
    RAISE NOTICE 'Mount Everest descriptors: %', everest_descriptors;
  END;

  RAISE NOTICE '';
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'DIAGNOSIS COMPLETE';
  RAISE NOTICE '============================================================';
END $$;
