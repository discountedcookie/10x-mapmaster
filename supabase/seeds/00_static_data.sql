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

-- LLM
('llm.enabled', 'true'::jsonb, 'Master toggle for all LLM functionality'),

-- LLM Trait Extraction (gemma3:1b with JSON format)
('llm.trait_extraction.model', '"gemma3:1b"'::jsonb, 'Ollama model - small but accurate'),
('llm.trait_extraction.temperature', '0.3'::jsonb, 'Slightly creative but focused'),
('llm.trait_extraction.num_predict', '250'::jsonb, 'Enough for 5 traits in JSON'),
('llm.trait_extraction.top_p', '0.85'::jsonb, 'Tighter sampling'),
('llm.trait_extraction.stop', '[]'::jsonb, 'No stop sequences needed for JSON'),
('llm.trait_extraction.format', '"json"'::jsonb, 'JSON output format'),
('llm.trait_extraction.prompt', '"Extract 3-5 distinctive traits for a guessing game. Traits must be generic characteristics, NOT location-specific.\n\nRules:\n- Use categories: style, era, feature, status, material, size\n- Clauses should work without knowing the place name\n- Do NOT mention city/country/location names in clauses\n\nExample: {\"traits\": [{\"id\": \"style:gothic\", \"clause\": \"Gothic architectural style\"}, {\"id\": \"material:iron\", \"clause\": \"Iron lattice construction\"}]}\n\nInput: {{nominatim_json}}\nOutput:"'::jsonb, 'Generic traits, no locations'),

-- LLM Question Generation
('llm.question.model', '"gemma3:1b"'::jsonb, 'Ollama model'),
('llm.question.temperature', '0.7'::jsonb, 'Temperature'),
('llm.question.num_predict', '100'::jsonb, 'Max tokens'),
('llm.question.top_p', '0.9'::jsonb, 'Top-p sampling'),
('llm.question.stop', '["\n"]'::jsonb, 'Stop sequences'),
('llm.question.format', 'null'::jsonb, 'Output format'),
('llm.question.trait_prompt', '"Generate a natural yes/no question asking if a place has this characteristic: {{trait_clause}}\n\nOutput ONLY the question."'::jsonb, 'Trait question prompt'),
('llm.question.region_prompt', '"Generate a natural yes/no question asking if a place is located in: {{region_name}}\n\nOutput ONLY the question."'::jsonb, 'Region question prompt'),

-- Confidence decision thresholds
('confidence.top_prob_threshold', '0.4'::jsonb, 'Minimum top probability to guess'),
('confidence.margin_threshold', '0.15'::jsonb, 'Minimum margin (gap between top two) to guess'),
('confidence.entropy_threshold', '0.7'::jsonb, 'Maximum normalized entropy to guess (lower = more certain)'),

-- Scoring configuration
('scoring.temperature', '1.0'::jsonb, 'Temperature for probability softmax. Lower = sharper distribution'),
('scoring.trait_aggregation_temperature', '0.1'::jsonb, 'Temperature for trait similarity aggregation. Lower = best traits dominate'),
('scoring.initial_candidate_threshold', '0.1'::jsonb, 'Minimum aggregated trait score to become a candidate'),
('scoring.max_initial_candidates', '100'::jsonb, 'Maximum number of initial candidates'),

-- Trait matching (binary via place_traits, multiplicative adjustments)
('traits.boost_factor', '1.5'::jsonb, 'Score multiplier when trait ownership matches answer'),
('traits.penalty_factor', '0.6'::jsonb, 'Score multiplier when trait ownership contradicts answer'),

-- Question selection
('questions.min_split_quality', '0.3'::jsonb, 'Minimum acceptable split quality for questions'),
('questions.geographic_preference_threshold', '0.7'::jsonb, 'Geographic split quality to prefer over semantic'),
('questions.use_llm_generation', 'true'::jsonb, 'Use LLM to generate natural question text instead of templates');
