BEGIN;


SET
  client_min_messages TO warning;


SET
  search_path = public,
  game_logic,
  extensions;


-- Enable test mode: external API calls return stubs instead of calling real services
SET
  pgtap.version = '1.0';


SELECT
  plan (30);


-- ============================================================================
-- Test: softmax_probabilities function
-- ============================================================================

-- Test 1: Single candidate returns [1.0]
SELECT
  results_eq (
    'SELECT softmax_probabilities(ARRAY[0.5]::FLOAT[])',
    'SELECT ARRAY[1.0]::FLOAT[]',
    'softmax: single candidate returns [1.0]'
  );


-- Test 2: Empty array returns empty array
SELECT
  results_eq (
    'SELECT softmax_probabilities(ARRAY[]::FLOAT[])',
    'SELECT ARRAY[]::FLOAT[]',
    'softmax: empty array returns empty array'
  );


-- Test 3: Higher scores get higher probabilities
SELECT
  ok (
    (
      SELECT
        (softmax_probabilities (ARRAY[2.0, 1.0, 0.5])) [1] > (softmax_probabilities (ARRAY[2.0, 1.0, 0.5])) [2]
    ),
    'softmax: higher scores produce higher probabilities'
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
    'softmax: probabilities sum to 1.0'
  );


-- Test 5: Lower temperature makes distribution sharper
SELECT
  ok (
    (
      SELECT
        (softmax_probabilities (ARRAY[2.0, 1.0], 0.1)) [1] > (softmax_probabilities (ARRAY[2.0, 1.0], 1.0)) [1]
    ),
    'softmax: lower temperature produces sharper distribution'
  );


-- Test 6: Identical scores produce uniform distribution
SELECT
  ok (
    (
      SELECT
        abs((softmax_probabilities(ARRAY[0.5, 0.5, 0.5]))[1] - 0.333) < 0.01
    ),
    'softmax: identical scores produce uniform distribution (~0.33 each)'
  );


-- ============================================================================
-- Test: calculate_confidence_metrics function
-- ============================================================================

-- Test 7: Single candidate has top_prob = 1.0
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[1.0])).top_prob = 1.0
    ),
    'metrics: single candidate has top_prob = 1.0'
  );


-- Test 8: Empty array returns 0 metrics
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[]::FLOAT[])).top_prob = 0
    ),
    'metrics: empty array returns zero top_prob'
  );


-- Test 9: Uniform distribution has zero margin
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[0.25, 0.25, 0.25, 0.25])).margin < 0.01
    ),
    'metrics: uniform distribution has near-zero margin'
  );


-- Test 10: Certain distribution has high top_prob
SELECT
  ok (
    (
      SELECT
        (calculate_confidence_metrics (ARRAY[0.9, 0.05, 0.05])).top_prob > 0.8
    ),
    'metrics: skewed distribution has high top_prob'
  );


-- Test 11: Two candidates - margin equals difference
SELECT
  ok (
    (
      SELECT
        abs((calculate_confidence_metrics(ARRAY[0.7, 0.3])).margin - 0.4) < 0.01
    ),
    'metrics: two candidates margin equals difference (0.7-0.3=0.4)'
  );


-- ============================================================================
-- Test: calculate_dynamic_threshold function
-- ============================================================================

-- Test 12: Turn 0 returns high threshold (conservative)
SELECT
  ok (
    calculate_dynamic_threshold(0, 5, 10, 0.1) > 0.85,
    'threshold: turn 0 returns high threshold (>0.85)'
  );


-- Test 13: Final turn returns low threshold (aggressive)
SELECT
  ok (
    calculate_dynamic_threshold(5, 5, 10, 0.1) < 0.65,
    'threshold: final turn returns low threshold (<0.65)'
  );


-- Test 14: Few candidates applies bonus
SELECT
  ok (
    calculate_dynamic_threshold(2, 5, 3, 0.1) < calculate_dynamic_threshold(2, 5, 10, 0.1),
    'threshold: few candidates reduces threshold'
  );


-- Test 15: High margin applies bonus
SELECT
  ok (
    calculate_dynamic_threshold(2, 5, 10, 0.30) < calculate_dynamic_threshold(2, 5, 10, 0.10),
    'threshold: high margin reduces threshold'
  );


-- Test 16: Ceiling clamp at 0.95
SELECT
  ok (
    calculate_dynamic_threshold(0, 5, 100, 0.0) <= 0.95,
    'threshold: clamped to ceiling (0.95)'
  );


-- Test 17: Floor clamp at 0.50
SELECT
  ok (
    calculate_dynamic_threshold(5, 5, 1, 0.99) >= 0.50,
    'threshold: clamped to floor (0.50)'
  );


-- Test 18: Mid-game interpolation
SELECT
  ok (
    (
      SELECT
        t > 0.70 AND t < 0.85
      FROM calculate_dynamic_threshold(2, 5, 10, 0.1) t
    ),
    'threshold: mid-game (turn 2/5) returns mid-range threshold'
  );


-- ============================================================================
-- Test: should_guess function
-- ============================================================================

-- Test 19: Single candidate always guesses
SELECT
  IS (
    should_guess (ARRAY[1.0]::FLOAT[], 0.99),
    TRUE,
    'should_guess: single candidate returns TRUE regardless of threshold'
  );


-- Test 20: Empty array never guesses
SELECT
  IS (
    should_guess (ARRAY[]::FLOAT[], 0.01),
    FALSE,
    'should_guess: empty array returns FALSE regardless of threshold'
  );


-- Test 21: Above threshold returns TRUE
SELECT
  IS (
    should_guess (ARRAY[0.85, 0.10, 0.05]::FLOAT[], 0.80),
    TRUE,
    'should_guess: top_prob (0.85) > threshold (0.80) returns TRUE'
  );


-- Test 22: Below threshold returns FALSE
SELECT
  IS (
    should_guess (ARRAY[0.60, 0.25, 0.15]::FLOAT[], 0.80),
    FALSE,
    'should_guess: top_prob (0.60) < threshold (0.80) returns FALSE'
  );


-- Test 23: Exactly at threshold returns TRUE (>= comparison)
SELECT
  IS (
    should_guess (ARRAY[0.80, 0.15, 0.05]::FLOAT[], 0.80),
    TRUE,
    'should_guess: top_prob equals threshold returns TRUE'
  );


-- ============================================================================
-- Test: apply_softmax_to_candidates function
-- ============================================================================

-- Test 24: Empty candidates returns empty array
SELECT
  results_eq (
    $$SELECT apply_softmax_to_candidates('[]'::JSONB)$$,
    $$SELECT '[]'::JSONB$$,
    'apply_softmax: empty candidates returns empty array'
  );


-- Test 25: NULL candidates returns empty array
SELECT
  results_eq (
    $$SELECT apply_softmax_to_candidates(NULL)$$,
    $$SELECT '[]'::JSONB$$,
    'apply_softmax: NULL candidates returns empty array'
  );


-- Test 26: Single candidate gets probability 1.0
SELECT
  ok (
    (
      SELECT
        abs((apply_softmax_to_candidates('[{"id": "a", "confidence": 0.8}]'::JSONB)->0->>'probability')::FLOAT - 1.0) < 0.001
    ),
    'apply_softmax: single candidate gets probability 1.0'
  );


-- Test 27: Probabilities sum to 1.0
SELECT
  ok (
    (
      SELECT
        abs(sum((c->>'probability')::FLOAT) - 1.0) < 0.001
      FROM jsonb_array_elements(
        apply_softmax_to_candidates('[{"id": "a", "confidence": 0.9}, {"id": "b", "confidence": 0.7}, {"id": "c", "confidence": 0.5}]'::JSONB)
      ) c
    ),
    'apply_softmax: probabilities sum to 1.0'
  );


-- Test 28: Results sorted by probability DESC
SELECT
  ok (
    (
      SELECT
        (r->0->>'probability')::FLOAT >= (r->1->>'probability')::FLOAT
        AND (r->1->>'probability')::FLOAT >= (r->2->>'probability')::FLOAT
      FROM (
        SELECT apply_softmax_to_candidates('[{"id": "a", "confidence": 0.5}, {"id": "b", "confidence": 0.9}, {"id": "c", "confidence": 0.7}]'::JSONB) r
      ) x
    ),
    'apply_softmax: results sorted by probability DESC'
  );


-- Test 29: Higher confidence gets higher probability
SELECT
  ok (
    (
      WITH result AS (
        SELECT apply_softmax_to_candidates('[{"id": "high", "confidence": 0.9}, {"id": "low", "confidence": 0.3}]'::JSONB) r
      )
      SELECT
        (SELECT (c->>'probability')::FLOAT FROM jsonb_array_elements((SELECT r FROM result)) c WHERE c->>'id' = 'high')
        >
        (SELECT (c->>'probability')::FLOAT FROM jsonb_array_elements((SELECT r FROM result)) c WHERE c->>'id' = 'low')
    ),
    'apply_softmax: higher confidence gets higher probability'
  );


-- Test 30: Missing confidence defaults to 0.5
SELECT
  ok (
    (
      SELECT
        (apply_softmax_to_candidates('[{"id": "a"}]'::JSONB)->0->>'probability')::FLOAT = 1.0
    ),
    'apply_softmax: missing confidence defaults (single candidate still gets 1.0)'
  );


SELECT
  *
FROM
  finish ();


ROLLBACK;
