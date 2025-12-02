-- Static seed data that doesn't require embeddings
-- Contains users and other non-embedding dependent data
SET
  search_path = public,
  extensions;

-- Increase statement timeout for service_role (LLM calls need >22s, default is 8s)
ALTER ROLE service_role SET statement_timeout = '120s';
NOTIFY pgrst, 'reload config';

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

-- LLM Trait Extraction (unified flow)
('llm.trait_extraction.model', '"meituan/longcat-flash-chat:free"'::jsonb, 'OpenRouter model ID'),
('llm.trait_extraction.fallback_model', '"cognitivecomputations/dolphin-mistral-24b-venice-edition:free"'::jsonb, 'Fallback model'),
('llm.trait_extraction.temperature', '0.1'::jsonb, 'Low temperature for factual responses'),
('llm.trait_extraction.num_predict', '1000'::jsonb, 'Max tokens'),
('llm.trait_extraction.top_p', '0.85'::jsonb, 'Top-p sampling'),
('llm.trait_extraction.stop', '[]'::jsonb, 'Stop sequences'),
('llm.trait_extraction.frequency_penalty', '0.3'::jsonb, 'Frequency penalty'),
('llm.trait_extraction.presence_penalty', '0.3'::jsonb, 'Presence penalty'),
('llm.trait_extraction.json_schema', '{
  "name": "traits",
  "strict": true,
  "schema": {
    "type": "object",
    "properties": {
      "traits": {
        "type": "array",
        "items": {"type": "string"}
      }
    },
    "required": ["traits"],
    "additionalProperties": false
  }
}'::jsonb, 'JSON schema for structured output'),
('llm.trait_extraction.max_traits', '20'::jsonb, 'Maximum traits per place'),
('llm.trait_extraction.prompt', '"You are updating a geographic guessing game database with traits for a place.\n\nPlace: {place_name}\nLocation: ({lat}, {lng})\nCountry: {country}\nType: {place_type}\n\nNominatim data:\n{nominatim_json}\n\nExisting traits:\n{existing_traits}\n\nUser descriptions from gameplay:\n{session_descriptions}\n\nGame answers (yes/no responses about this place):\n{game_answers}\n\nTask: Return the BEST 10-{max_traits} traits for this place.\n- Use your WORLD KNOWLEDGE combined with the data above\n- Keep useful existing traits, add new specific ones, drop generic/redundant ones\n- Focus on SPECIFIC FACTS: dimensions, dates, materials, architects, historical events, records\n- Clause should be a short human-readable description\n- Do NOT mention the place name in clauses\n- Prefer specific over generic (\"324 meters tall\" > \"Is tall\")"'::jsonb, 'Unified prompt for trait extraction/update'),

-- LLM Question Generation
('llm.question.model', '"google/gemma-3-4b-it:free"'::jsonb, 'OpenRouter model ID'),
('llm.question.fallback_model', '"google/gemma-3n-e2b-it:free"'::jsonb, 'OpenRouter model ID'),
('llm.question.temperature', '0.3'::jsonb, 'Temperature'),
('llm.question.num_predict', '50'::jsonb, 'Max tokens'),
('llm.question.top_p', '0.9'::jsonb, 'Top-p sampling'),
('llm.question.stop', '[]'::jsonb, 'Stop sequences'),
('llm.question.trait_prompt', '"You write natural yes/no questions for a guessing game.\n\nLanguage code: <lang>{language_code}</lang>\nUser description: {user_description}\nTrait clause: {trait_clause}\n\nWrite one short, natural yes/no question in the requested language, using \"it\" to refer to the mystery place. Answer should help the game understand whether the trait applies. Return ONLY the question text."'::jsonb, 'Trait question prompt with language and context'),
('llm.question.region_prompt', '"You write natural yes/no questions for a guessing game.\n\nLanguage code: <lang>{language_code}</lang>\nUser description: {user_description}\nRegion name: {region_name}\n\nWrite one short, natural yes/no question in the requested language about whether the place is in that region. Use \"it\" for the mystery place. Return ONLY the question text."'::jsonb, 'Region question prompt with language and context'),

-- Confidence decision thresholds
('confidence.top_prob_threshold', '0.4'::jsonb, 'Minimum top probability to guess'),
('confidence.margin_threshold', '0.15'::jsonb, 'Minimum margin (gap between top two) to guess'),
('confidence.entropy_threshold', '0.7'::jsonb, 'Maximum normalized entropy to guess (lower = more certain)'),

-- Scoring configuration
('scoring.temperature', '1.0'::jsonb, 'Temperature for probability softmax. Lower = sharper distribution'),
('scoring.trait_aggregation_temperature', '0.1'::jsonb, 'Temperature for trait similarity aggregation. Lower = best traits dominate'),
('scoring.initial_candidate_threshold', '0.3'::jsonb, 'Minimum aggregated trait score to become a candidate'),
('scoring.max_initial_candidates', '100'::jsonb, 'Maximum number of initial candidates'),

-- Trait matching (binary via place_traits, multiplicative adjustments)
('traits.boost_factor', '1.5'::jsonb, 'Score multiplier when trait ownership matches answer'),
('traits.penalty_factor', '0.6'::jsonb, 'Score multiplier when trait ownership contradicts answer'),

-- Question selection
('questions.min_split_quality', '0.3'::jsonb, 'Minimum acceptable split quality for questions'),
('questions.geographic_preference_threshold', '0.7'::jsonb, 'Geographic split quality to prefer over semantic'),
('questions.use_llm_generation', 'true'::jsonb, 'Use LLM to generate natural question text instead of templates');
