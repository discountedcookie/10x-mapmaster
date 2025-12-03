BEGIN;


SET
  client_min_messages TO warning;


SET
  search_path = public,
  game_logic,
  extensions;


SELECT
  plan (25);


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
    (
      SELECT
        (softmax_probabilities (ARRAY[2.0, 1.0, 0.5])) [1] > (softmax_probabilities (ARRAY[2.0, 1.0, 0.5])) [2]
    ),
    'Higher scores produce higher probabilities'
  );


-- Test 4: Probabilities sum to approximately 1.0
SELECT
  ok (
    (
      SELECT
        abs(sum(x) - 1.0) < 0.001
      FROM
        unnest(softmax_probabilities (ARRAY[1.5, 0.8, 2.1, 0.3])) AS x
    ),
    'Probabilities sum to 1.0'
  );


-- Test 5: Lower temperature makes distribution sharper (higher max probability)
SELECT
  ok (
    (
      SELECT
        (softmax_probabilities (ARRAY[2.0, 1.0], 0.1)) [1] > (softmax_probabilities (ARRAY[2.0, 1.0], 1.0)) [1]
    ),
    'Lower temperature produces sharper distribution'
  );


-- Test: calculate_confidence_metrics function
-- Test 6: Single candidate has top_prob = 1.0
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[1.0])).top_prob = 1.0
    ),
    'Single candidate has top_prob = 1.0'
  );


-- Test 7: Empty array returns 0 metrics (no candidates)
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[]::FLOAT[])).top_prob = 0
    ),
    'Empty array returns zero top_prob'
  );


-- Test 8: Uniform distribution has low margin (close to 0)
SELECT
  ok (
    (
      SELECT
        (
          calculate_confidence_metrics (ARRAY[0.25, 0.25, 0.25, 0.25])
        ).margin < 0.01
    ),
    'Uniform distribution has near-zero margin'
  );


-- Test 9: Certain distribution has high top_prob (>0.8)
SELECT
  ok (
    (
      SELECT
        (
          calculate_confidence_metrics (ARRAY[0.9, 0.05, 0.05])
        ).top_prob > 0.8
    ),
    'Certain distribution has high top_prob'
  );


-- Test: calculate_dynamic_threshold function
-- Test 10: At turn 0 with many candidates, returns high threshold (conservative)
SELECT
  ok (
    calculate_dynamic_threshold(0, 5, 10, 0.1) > 0.85,
    'Turn 0 with many candidates returns high threshold'
  );


-- Test 11: At final turn with many candidates, returns lower threshold (aggressive)
SELECT
  ok (
    calculate_dynamic_threshold(5, 5, 10, 0.1) < 0.65,
    'Final turn with many candidates returns lower threshold'
  );


-- Test 12: With few candidates (<=3), applies candidate bonus
SELECT
  ok (
    calculate_dynamic_threshold(2, 5, 3, 0.1) < calculate_dynamic_threshold(2, 5, 10, 0.1),
    'Few candidates reduces threshold (candidate bonus applied)'
  );


-- Test 13: With high margin (>=0.25), applies margin bonus
SELECT
  ok (
    calculate_dynamic_threshold(2, 5, 10, 0.30) < calculate_dynamic_threshold(2, 5, 10, 0.10),
    'High margin reduces threshold (margin bonus applied)'
  );


-- Test 14: Both bonuses stack additively
SELECT
  ok (
    calculate_dynamic_threshold(2, 5, 3, 0.30) < calculate_dynamic_threshold(2, 5, 3, 0.10),
    'Bonuses stack additively'
  );


-- Test 15: Result is clamped between floor and ceiling
SELECT
  ok (
    calculate_dynamic_threshold(0, 5, 100, 0.1) <= 0.95,
    'Threshold clamped to ceiling (0.95)'
  );


-- Test 16: Result is clamped between floor and ceiling
SELECT
  ok (
    calculate_dynamic_threshold(5, 5, 1, 0.50) >= 0.50,
    'Threshold clamped to floor (0.50)'
  );


-- Test: should_guess function (updated for dynamic threshold)
-- Test 17: Single candidate returns TRUE (only one option = should guess)
SELECT
  IS (
    should_guess (ARRAY[1.0], 0, 5, 1),
    TRUE,
    'Single candidate returns TRUE (must guess)'
  );


-- Test 18: Empty array returns FALSE (no candidates = cannot guess)
SELECT
  IS (
    should_guess (ARRAY[]::FLOAT[], 0, 5, 0),
    FALSE,
    'Empty array returns FALSE (no candidates)'
  );


-- Test 19: High confidence at start returns TRUE (when meets dynamic threshold)
SELECT
  IS (
    should_guess (ARRAY[0.85, 0.1, 0.05], 0, 5, 3),
    TRUE,
    'High confidence (0.85) returns TRUE at turn 0 with 3 candidates'
  );


-- Test 20: Lower confidence at final turn also returns TRUE (lower threshold)
SELECT
  IS (
    should_guess (ARRAY[0.65, 0.25, 0.1], 5, 5, 10),
    TRUE,
    'Moderate confidence (0.65) returns TRUE at final turn with many candidates'
  );


-- Test: calculate_split_quality function
-- Test 21: 50% match gives highest quality (perfect split)
SELECT
  ok (
    calculate_split_quality (5, 10) > 0.9,
    '50% match gives high split quality (perfect split)'
  );


-- Test 22: 0% match gives low quality (no information gain)
SELECT
  ok (
    calculate_split_quality (0, 10) < 0.6,
    '0% match gives low quality'
  );


-- Test 23: 100% match gives low quality (no information gain)
SELECT
  ok (
    calculate_split_quality (10, 10) < 0.6,
    '100% match gives low quality'
  );


-- Test: adjust_score function
-- Test 24: Not sure answer returns original score unchanged
SELECT
  ok (
    abs(
      adjust_score (0.5, 0.8, 'STRONG', 'not_sure') - 0.5
    ) < 0.01,
    'Not sure answer returns original score'
  );


-- Test 25: Yes + strong match increases score
SELECT
  ok (
    adjust_score (0.5, 0.8, 'STRONG', 'yes') > 0.5,
    'Yes + strong match increases score'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
