-- Game configuration required for production
-- These are inserted during migration, not seeds
-- Runtime keys (runtime.*) are NOT included here - they go in dev-only seeds

INSERT INTO game_logic.config (key, value, description) VALUES
-- Game settings
('game.max_turns', '5'::jsonb, 'Maximum number of turns before forcing a final guess attempt'),

-- LLM
('llm.enabled', 'true'::jsonb, 'Master toggle for all LLM functionality'),

-- LLM Trait Extraction (unified flow)
('llm.trait_extraction.model', '"meituan/longcat-flash-chat:free"'::jsonb, 'OpenRouter model ID'),
('llm.trait_extraction.fallback_model', '"cognitivecomputations/dolphin-mistral-24b-venice-edition:free"'::jsonb, 'Fallback model'),
('llm.trait_extraction.temperature', '0.1'::jsonb, 'Low temperature for factual responses'),
('llm.trait_extraction.max_tokens', '1000'::jsonb, 'Max tokens'),
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
('llm.question.fallback_model', '"google/gemma-3n-e2b-it:free"'::jsonb, 'Fallback model'),
('llm.question.temperature', '0.3'::jsonb, 'Randomness (lower = more deterministic)'),
('llm.question.max_tokens', '50'::jsonb, 'Max tokens'),
('llm.question.top_p', '0.9'::jsonb, 'Nucleus sampling threshold'),
('llm.question.top_k', '40'::jsonb, 'Only consider top K tokens (0=disabled)'),
('llm.question.min_p', '0.05'::jsonb, 'Minimum probability threshold relative to top token'),
('llm.question.stop', '["?"]'::jsonb, 'Stop on question mark to avoid duplication'),
('llm.question.trait_prompt', '"<trait>{trait_clause}</trait>\n<language>{language_code}</language>\n\nAsk a short yes/no question about whether it has this trait.\nGeneralize: dates → recently, numbers → very tall/large.\nOutput only the question."'::jsonb, 'Trait question prompt (turn 2+) - uses "it" as subject'),
('llm.question.region_prompt', '"<region>{region_name}</region>\n<language>{language_code}</language>\n\nAsk: Is it in {region_name}?\nOutput only the question."'::jsonb, 'Region question prompt (turn 2+) - uses "it" as subject'),
('llm.question.trait_prompt_turn1', '"<description>{user_description}</description>\n<trait>{trait_clause}</trait>\n<language>{language_code}</language>\n\nAsk a short yes/no question about whether the thing in the description has this trait.\nUse the subject from the description naturally (e.g. this tower, this mountain).\nGeneralize: dates → recently, numbers → very tall/large.\nNever mention specific place names.\nOutput only the question."'::jsonb, 'Trait question prompt (turn 1) - extracts noun from user description'),
('llm.question.region_prompt_turn1', '"<description>{user_description}</description>\n<region>{region_name}</region>\n<language>{language_code}</language>\n\nAsk whether the thing in the description is located in the region.\nUse the subject from the description naturally (e.g. Is this tower in Europe?).\nNever mention specific place names.\nOutput only the question."'::jsonb, 'Region question prompt (turn 1) - extracts noun from user description'),

-- Confidence decision thresholds (dynamic system)
('confidence.guess_threshold_max', '0.90'::jsonb, 'Maximum threshold at turn 0 (conservative)'),
('confidence.guess_threshold_min', '0.60'::jsonb, 'Minimum threshold at final turn (aggressive)'),
('confidence.threshold_floor', '0.50'::jsonb, 'Absolute minimum threshold after all adjustments'),
('confidence.threshold_ceiling', '0.95'::jsonb, 'Absolute maximum threshold after all adjustments'),
('confidence.candidate_low_threshold', '3'::jsonb, 'Number of candidates below which bonus applies'),
('confidence.candidate_bonus', '0.10'::jsonb, 'Reduction in threshold when few candidates remain'),
('confidence.margin_high_threshold', '0.25'::jsonb, 'Margin between top two candidates triggering bonus'),
('confidence.margin_bonus', '0.10'::jsonb, 'Reduction in threshold when margin is high'),

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
