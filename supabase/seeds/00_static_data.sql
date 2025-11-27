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



-- ============================================================================
-- ALL CONFIGURATION IN game_logic.config (server-only, hierarchical keys)
-- ============================================================================
-- Note: app_settings table exists for backward compatibility but is no longer used.
-- All game logic reads from game_logic.config via get_config_*() functions.

INSERT INTO game_logic.config (key, value, description) VALUES
-- Runtime environment for LOCAL DEVELOPMENT ONLY
-- For production: set these via Supabase dashboard SQL editor or migrations
-- Uses host.docker.internal for Postgres-to-EdgeFunction calls (Docker networking)
-- These are the standard Supabase local dev keys (publicly documented)
('runtime.supabase_url', '"http://host.docker.internal:54321"'::jsonb, 'Supabase API URL (Docker internal)'),
('runtime.supabase_anon_key', '"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"'::jsonb, 'Supabase anon key (local dev)'),
('runtime.supabase_service_role_key', '"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"'::jsonb, 'Supabase service role key (local dev)'),

-- Game settings
('game.max_turns', '5'::jsonb, 'Maximum number of turns before forcing a final guess attempt'),

-- LLM Model Configuration
('llm.model', '"gemma3:1b"'::jsonb, 'Ollama model name for LLM operations'),
('llm.temperature', '0.1'::jsonb, 'LLM temperature (0.0-1.0). Lower = more deterministic'),
('llm.num_predict', '300'::jsonb, 'Maximum number of tokens to generate'),
('llm.top_p', '0.9'::jsonb, 'LLM top_p sampling control'),
('llm.stop', '["\n\n"]'::jsonb, 'JSON array of stop sequences'),

-- LLM Trait Extraction
('llm.extraction.enabled', 'true'::jsonb, 'Enable LLM trait extraction during place enrichment'),
('llm.extraction.prompt', '"Extract 3-5 distinctive traits for this place that would help someone guess it in a geographic game. Focus on physical characteristics, historical significance, cultural importance, or unique features. Avoid generic traits. Return JSON array: [{\"clause\": \"trait description\", \"category\": \"category\", \"confidence\": 0.8}]"'::jsonb, 'Prompt for LLM trait extraction'),
('llm.extraction.model', '"gemma3:1b"'::jsonb, 'Model to use for LLM trait extraction'),
('llm.extraction.temperature', '0.3'::jsonb, 'Temperature for LLM trait extraction'),

-- Confidence decision thresholds
('confidence.top_prob_threshold', '0.4'::jsonb, 'Minimum top probability to guess'),
('confidence.margin_threshold', '0.15'::jsonb, 'Minimum margin (gap between top two) to guess'),
('confidence.entropy_threshold', '0.7'::jsonb, 'Maximum normalized entropy to guess (lower = more certain)'),

-- Scoring configuration
('scoring.temperature', '1.0'::jsonb, 'Temperature for softmax. Lower = sharper distribution, higher = flatter'),
('scoring.geographic_fit_max_weight', '0.2'::jsonb, 'Maximum geographic fit bonus'),
('scoring.distance_normalization', '20000000.0'::jsonb, 'Distance normalization for geographic fit (~20000km)'),

-- Semantic filtering thresholds
('candidates.semantic_similarity_threshold', '0.5'::jsonb, 'Minimum base description similarity to include a place as candidate'),
('candidates.initial_threshold', '0.3'::jsonb, 'Minimum similarity for initial candidates'),
('candidates.max_initial', '100'::jsonb, 'Maximum number of initial candidates'),

-- Trait matching thresholds
('traits.similarity_threshold', '0.6'::jsonb, 'Threshold to determine if a place "has" a trait'),
('traits.strong_match_threshold', '0.7'::jsonb, 'Threshold for STRONG trait match'),
('traits.partial_match_threshold', '0.5'::jsonb, 'Threshold for PARTIAL trait match'),

-- Score adjustment weights
('adjustment.affirmed_trait_match', '0.3'::jsonb, 'Boost when place HAS affirmed trait'),
('adjustment.affirmed_trait_mismatch', '-0.2'::jsonb, 'Penalty when place lacks affirmed trait'),
('adjustment.denied_trait_match', '-0.4'::jsonb, 'Penalty when place HAS denied trait'),
('adjustment.denied_trait_mismatch', '0.1'::jsonb, 'Boost when place lacks denied trait'),
('adjustment.base_weight', '0.3'::jsonb, 'Base weight for score adjustments'),
('adjustment.beta', '1.5'::jsonb, 'Power-law exponent for adjustment magnitude'),

-- Question selection
('questions.min_split_quality', '0.6'::jsonb, 'Minimum acceptable split quality for questions'),
('questions.geographic_preference_threshold', '0.7'::jsonb, 'Geographic split quality to prefer over semantic');
