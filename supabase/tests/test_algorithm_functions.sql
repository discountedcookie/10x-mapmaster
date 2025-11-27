BEGIN;


SET
  client_min_messages TO warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (20);


-- Test: softmax_probabilities function
-- Test 1: Single candidate returns [1.0]
SELECT
  results_eq (
    'SELECT softmax_probabilities(ARRAY[0.5]::FLOAT[])',
    'SELECT ARRAY[1.0]::FLOAT[]',
    'Single candidate returns probability [1.0]'
  );


-- Test 2: Empty array returns empty array
SELECT
  results_eq (
    'SELECT softmax_probabilities(ARRAY[]::FLOAT[])',
    'SELECT ARRAY[]::FLOAT[]',
    'Empty array returns empty array'
  );


-- Test 3: Higher scores get higher probabilities
SELECT
  ok (
    (SELECT (softmax_probabilities(ARRAY[2.0, 1.0, 0.5]))[1] > (softmax_probabilities(ARRAY[2.0, 1.0, 0.5]))[2]),
    'Higher scores produce higher probabilities'
  );


-- Test 4: Probabilities sum to approximately 1.0
SELECT
  ok (
    (SELECT ABS(SUM(x) - 1.0) < 0.001 FROM unnest(softmax_probabilities(ARRAY[1.5, 0.8, 2.1, 0.3])) AS x),
    'Probabilities sum to 1.0'
  );


-- Test 5: Lower temperature makes distribution sharper (higher max probability)
SELECT
  ok (
    (SELECT (softmax_probabilities(ARRAY[2.0, 1.0], 0.1))[1] > (softmax_probabilities(ARRAY[2.0, 1.0], 1.0))[1]),
    'Lower temperature produces sharper distribution'
  );


-- Test: calculate_confidence_metrics function
-- Test 6: Single candidate has top_prob = 1.0
SELECT
  ok (
    (SELECT (calculate_confidence_metrics(ARRAY[1.0])).top_prob = 1.0),
    'Single candidate has top_prob = 1.0'
  );


-- Test 7: Empty array returns 0 metrics (no candidates)
SELECT
  ok (
    (SELECT (calculate_confidence_metrics(ARRAY[]::FLOAT[])).top_prob = 0),
    'Empty array returns zero top_prob'
  );


-- Test 8: Uniform distribution has low margin (close to 0)
SELECT
  ok (
    (SELECT (calculate_confidence_metrics(ARRAY[0.25, 0.25, 0.25, 0.25])).margin < 0.01),
    'Uniform distribution has near-zero margin'
  );


-- Test 9: Certain distribution has high top_prob (>0.8)
SELECT
  ok (
    (SELECT (calculate_confidence_metrics(ARRAY[0.9, 0.05, 0.05])).top_prob > 0.8),
    'Certain distribution has high top_prob'
  );


-- Test: should_guess function
-- Test 10: Single candidate returns TRUE (only one option = should guess)
SELECT
  IS (
    should_guess(ARRAY[1.0]),
    TRUE,
    'Single candidate returns TRUE (must guess)'
  );


-- Test 11: Empty array returns FALSE (no candidates = cannot guess)
SELECT
  IS (
    should_guess(ARRAY[]::FLOAT[]),
    FALSE,
    'Empty array returns FALSE (no candidates)'
  );


-- Test 12: Uniform distribution returns FALSE (too uncertain)
SELECT
  IS (
    should_guess(ARRAY[0.25, 0.25, 0.25, 0.25]),
    FALSE,
    'Uniform distribution returns FALSE (too uncertain)'
  );


-- Test 13: High confidence returns TRUE
SELECT
  IS (
    should_guess(ARRAY[0.8, 0.1, 0.1]),
    TRUE,
    'High confidence (0.8) returns TRUE'
  );


-- Test 14: Low confidence returns FALSE
SELECT
  IS (
    should_guess(ARRAY[0.3, 0.25, 0.25, 0.2]),
    FALSE,
    'Low confidence (0.3) returns FALSE'
  );


-- Test 15: Custom thresholds - relaxed entropy allows guess
-- Probs [0.5, 0.3, 0.2] have entropy 0.94, so need entropy_threshold > 0.94
SELECT
  IS (
    should_guess(ARRAY[0.5, 0.3, 0.2], 0.4, 0.15, 0.95),
    TRUE,
    'Custom thresholds (relaxed entropy) allow guess'
  );


-- Test: calculate_split_quality function
-- Test 16: 50% match gives highest quality (perfect split)
SELECT
  ok (
    calculate_split_quality(5, 10) > 0.9,
    '50% match gives high split quality (perfect split)'
  );


-- Test 17: 0% match gives low quality (no information gain)
SELECT
  ok (
    calculate_split_quality(0, 10) < 0.6,
    '0% match gives low split quality'
  );


-- Test 18: 100% match gives low quality (no information gain)
SELECT
  ok (
    calculate_split_quality(10, 10) < 0.6,
    '100% match gives low split quality'
  );


-- Test: adjust_score function
-- Test 19: Not sure answer returns original score unchanged
SELECT
  ok (
    ABS(adjust_score(0.5, 0.8, 'STRONG', 'not_sure') - 0.5) < 0.01,
    'Not sure answer returns original score'
  );


-- Test 20: Yes + strong match increases score
SELECT
  ok (
    adjust_score(0.5, 0.8, 'STRONG', 'yes') > 0.5,
    'Yes + strong match increases score'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
