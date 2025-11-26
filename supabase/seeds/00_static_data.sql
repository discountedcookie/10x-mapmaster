-- Static seed data that doesn't require embeddings
-- Contains users and other non-embedding dependent data
SET
  search_path = public,
  extensions;

-- Create test users
INSERT INTO
  auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
  )
VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'user1@example.com',
    extensions.crypt ('password123', extensions.gen_salt ('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'test@example.com',
    extensions.crypt ('password123', extensions.gen_salt ('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

-- LLM System Prompt (single prompt for all LLM operations)
INSERT INTO app_settings (key, value, description)
VALUES (
  'llm_prompt',
  'You are a strict JSON generator for a place-guessing game.

### RULES
1. Create a question that splits the candidates into two roughly equal groups.
2. Never repeat questions from "Previous Answers".
{rule3}

### OUTPUT FORMAT (EXAMPLES)
{geo_example}If inventing a Semantic Question:
{"type": "semantic", "lang": "{language}", "question": "Is it white?", "semantic_trait": "Color white", "reasoning": "<reasoning>"}

### DATA CONTEXT
{description}{answers}{candidates}{geographic_regions}

### YOUR RESPONSE
Produce the single-line JSON based on the DATA above.',
  'System prompt for LLM question selection using section placeholders'
);

-- LLM Model Configuration
INSERT INTO app_settings (key, value, description) VALUES
('llm_model', 'gemma3:1b', 'Ollama model name for LLM operations.'),
('llm_temperature', '0.1', 'LLM temperature (0.0-1.0). Lower = more deterministic.'),
('llm_num_predict', '300', 'Maximum number of tokens to generate.'),
('llm_top_p', '0.9', 'LLM top_p sampling control.'),
('llm_stop', '["\n\n"]', 'JSON array of stop sequences.');

-- Game configuration: Maximum turns before forced final guess
INSERT INTO app_settings (key, value, description) VALUES
('max_turns', '5', 'Maximum number of turns before forcing a final guess attempt');

-- Guess policy thresholds
INSERT INTO app_settings (key, value, description) VALUES
('guess_confidence_threshold', '0.90', 'Minimum confidence score to trigger a guess (with gap requirement)'),
('guess_confidence_gap_threshold', '0.1', 'Minimum gap between top 2 candidates to trigger a guess'),
('guess_high_confidence_threshold', '1.0', 'High confidence threshold for immediate guess (ignores gap)');

-- Semantic filtering thresholds
INSERT INTO app_settings (key, value, description) VALUES
('semantic_similarity_threshold', '0.5', 'Minimum base description similarity to include a place as candidate.'),
('trait_similarity_threshold', '0.6', 'Threshold to determine if a place "has" a trait.');

-- Scoring weights
INSERT INTO app_settings (key, value, description) VALUES
('weight_affirmed_trait_match', '0.3', 'Boost when place HAS affirmed trait'),
('weight_affirmed_trait_mismatch', '-0.2', 'Penalty when place lacks affirmed trait'),
('weight_denied_trait_match', '-0.4', 'Penalty when place HAS denied trait'),
('weight_denied_trait_mismatch', '0.1', 'Boost when place lacks denied trait'),
('weight_geographic_fit_max', '0.2', 'Maximum geographic fit bonus'),
('geographic_distance_normalization', '20000000.0', 'Distance normalization for geographic fit');

-- Algorithm: Softmax probability distribution (spec/algorithm.md#probability-distribution)
INSERT INTO app_settings (key, value, description) VALUES
('softmax_temperature', '1.0', 'Temperature for softmax. Lower = sharper distribution, higher = flatter.');

-- Algorithm: Confidence decision metrics (spec/algorithm.md#confidence-decision-metrics)
INSERT INTO app_settings (key, value, description) VALUES
('top_prob_threshold', '0.4', 'Minimum top probability to guess'),
('margin_threshold', '0.15', 'Minimum margin (gap between top two) to guess'),
('entropy_threshold', '0.7', 'Maximum normalized entropy to guess (lower = more certain)');

-- Algorithm: Initial candidate selection (spec/algorithm.md#initial-candidate-scoring)
INSERT INTO app_settings (key, value, description) VALUES
('initial_candidate_threshold', '0.3', 'Minimum similarity for initial candidates'),
('max_initial_candidates', '100', 'Maximum number of initial candidates');

-- Algorithm: Trait matching (spec/algorithm.md#trait-match-scoring)
INSERT INTO app_settings (key, value, description) VALUES
('strong_match_threshold', '0.7', 'Threshold for STRONG trait match'),
('partial_match_threshold', '0.5', 'Threshold for PARTIAL trait match');

-- Algorithm: Score adjustment (spec/algorithm.md#score-adjustment)
INSERT INTO app_settings (key, value, description) VALUES
('adjustment_base_weight', '0.3', 'Base weight for score adjustments'),
('adjustment_beta', '1.5', 'Power-law exponent for adjustment magnitude');

-- Algorithm: Question selection (spec/algorithm.md#question-selection-algorithm)
INSERT INTO app_settings (key, value, description) VALUES
('min_split_quality', '0.6', 'Minimum acceptable split quality for questions'),
('geographic_preference_threshold', '0.7', 'Geographic split quality to prefer over semantic');
