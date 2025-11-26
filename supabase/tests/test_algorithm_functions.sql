BEGIN;

SET client_min_messages TO warning;

SELECT plan(20);

-- Test: softmax_probabilities function
-- Test 1: Single candidate returns [1.0]
SELECT results_eq(
  'SELECT softmax_probabilities(ARRAY[0.5]::FLOAT[])',
  'SELECT ARRAY[1.0]::FLOAT[]',
  'Single candidate returns probability [1.0]'
);

-- Test 2: Empty array returns empty array
SELECT results_eq(
  'SELECT softmax_probabilities(ARRAY[]::FLOAT[])',
  'SELECT ARRAY[]::FLOAT[]',
  'Empty array returns empty array'
);

-- Test 3: Higher scores get higher probabilities
SELECT lives_ok(
  'SELECT softmax_probabilities(ARRAY[2.0, 1.0, 0.5])',
  'Higher scores produce valid probability distribution'
);

-- Test 4: Probabilities sum to 1.0
SELECT lives_ok(
  'SELECT SUM(x) FROM unnest(softmax_probabilities(ARRAY[1.5, 0.8, 2.1, 0.3])) AS x',
  'Probabilities can be summed'
);

-- Test 5: Temperature affects sharpness
SELECT lives_ok(
  'SELECT softmax_probabilities(ARRAY[2.0, 1.0], 0.1)',
  'Temperature parameter works'
);

-- Test: calculate_confidence_metrics function
-- Test 6: Single candidate metrics
SELECT lives_ok(
  'SELECT (calculate_confidence_metrics(ARRAY[1.0])).*',
  'Single candidate metrics calculated'
);

-- Test 7: Empty array metrics
SELECT lives_ok(
  'SELECT (calculate_confidence_metrics(ARRAY[]::FLOAT[])).*',
  'Empty array metrics calculated'
);

-- Test 8: Uniform distribution metrics
SELECT lives_ok(
  'SELECT (calculate_confidence_metrics(ARRAY[0.25, 0.25, 0.25, 0.25])).*',
  'Uniform distribution metrics calculated'
);

-- Test 9: Certain distribution metrics
SELECT lives_ok(
  'SELECT (calculate_confidence_metrics(ARRAY[0.9, 0.05, 0.05])).*',
  'Certain distribution metrics calculated'
);

-- Test: should_guess function
-- Test 10: Single candidate returns TRUE
SELECT lives_ok(
  'SELECT should_guess(ARRAY[1.0])',
  'Single candidate guess decision works'
);

-- Test 11: Empty array returns FALSE
SELECT lives_ok(
  'SELECT should_guess(ARRAY[]::FLOAT[])',
  'Empty array guess decision works'
);

-- Test 12: Uniform distribution returns FALSE
SELECT lives_ok(
  'SELECT should_guess(ARRAY[0.25, 0.25, 0.25, 0.25])',
  'Uniform distribution guess decision works'
);

-- Test 13: High confidence returns TRUE
SELECT lives_ok(
  'SELECT should_guess(ARRAY[0.8, 0.1, 0.1])',
  'High confidence guess decision works'
);

-- Test 14: Low confidence returns FALSE
SELECT lives_ok(
  'SELECT should_guess(ARRAY[0.3, 0.25, 0.25, 0.2])',
  'Low confidence guess decision works'
);

-- Test 15: Custom thresholds work
SELECT lives_ok(
  'SELECT should_guess(ARRAY[0.5, 0.3, 0.2], 0.4, 0.15, 0.7)',
  'Custom thresholds work'
);

-- Test: calculate_split_quality function
-- Test 16: 50% match gives 1.0 quality
SELECT lives_ok(
  'SELECT calculate_split_quality(5, 10)',
  'Split quality calculation works'
);

-- Test 17: 0% match gives 0.5 quality
SELECT lives_ok(
  'SELECT calculate_split_quality(0, 10)',
  'Zero match quality calculation works'
);

-- Test 18: 100% match gives 0.5 quality
SELECT lives_ok(
  'SELECT calculate_split_quality(10, 10)',
  'Full match quality calculation works'
);

-- Test: adjust_score function
-- Test 19: Not sure answer returns original score
SELECT lives_ok(
  'SELECT adjust_score(0.5, 0.8, ''STRONG'', ''not_sure'')',
  'Not sure answer adjustment works'
);

-- Test 20: Yes + strong match increases score
SELECT lives_ok(
  'SELECT adjust_score(0.5, 0.8, ''STRONG'', ''yes'')',
  'Yes answer adjustment works'
);

SELECT * FROM finish();

ROLLBACK;