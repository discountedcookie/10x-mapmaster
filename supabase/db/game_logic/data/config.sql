-- Game configuration required for production
-- These are inserted during migration, not seeds
-- Runtime keys (runtime.*) are NOT included here - they go in dev-only seeds
-- Description should describe the field, not the value

INSERT INTO game_logic.config (key, value, description) VALUES
-- Game settings
('game.max_turns', '5'::jsonb, 'Maximum number of turns before forcing a final guess attempt'),

-- LLM
('llm.enabled', 'true'::jsonb, 'Master toggle for all LLM functionality'),

-- LLM Trait Extraction (unified flow)
('llm.trait_extraction.model', '"meituan/longcat-flash-chat:free"'::jsonb, 'OpenRouter model ID'),
('llm.trait_extraction.fallback_model', '"cognitivecomputations/dolphin-mistral-24b-venice-edition:free"'::jsonb, 'Fallback model'),
('llm.trait_extraction.temperature', '0.15'::jsonb, 'Randomness (lower = more deterministic)'),
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
('llm.trait_extraction.max_traits', '30'::jsonb, 'Maximum traits per place'),
('llm.trait_extraction.prompt', '"You are curating a knowledge base for a geographic guessing game.\n\nPLACE: {place_name}\nLOCATION: ({lat}, {lng}) in {country}\nTYPE: {place_type}\n\nSOURCE DATA:\n{nominatim_text}\n\nCURRENT KNOWLEDGE:\n{existing_traits}\n\nNEW INFORMATION:\nUser descriptions: {session_descriptions}\nConfirmed facts: {game_answers}\n\nTASK: Curate the knowledge base. Stay within {max_traits} traits total.\n\nKEY PRINCIPLES:\n- PRESERVE existing traits exactly as written. Do not rephrase or reword them.\n- ADD new facts ONLY if substantively different from existing traits.\n- CONSOLIDATE only truly similar traits into one. If uncertain, keep both.\n- REMOVE outdated, generic, or unverifiable information.\n\nTRAIT REQUIREMENTS:\n- Each trait: complete, naturally readable statement (5-25 words)\n- Include specifics: measurements, dates, materials, architects, events\n- Write as facts a curious traveler would find interesting\n- NO hex color codes like #787878. Use words: dark gray stone, tan stucco.\n- ENGLISH ONLY. No Cyrillic, Arabic, CJK, Khmer, or other non-Latin scripts.\n- No place names, no generic adjectives (famous, beautiful), no visitor logistics.\n\nOUTPUT FORMAT (JSON):\n{\n  \"traits\": [\"trait 1\", \"trait 2\", ...],\n  \"changes\": \"Brief note about what was added/removed and why\"\n}"'::jsonb, 'Unified prompt for trait extraction/update'),

-- LLM Question Generation
('llm.question.model', '"mistralai/mistral-7b-instruct:free"'::jsonb, 'OpenRouter model ID'),
('llm.question.fallback_model', '"google/gemma-3-4b-it:free"'::jsonb, 'Fallback model'),
('llm.question.temperature', '0.3'::jsonb, 'Randomness (lower = more deterministic)'),
('llm.question.max_tokens', '50'::jsonb, 'Max tokens'),
('llm.question.top_p', '0.9'::jsonb, 'Nucleus sampling threshold'),
('llm.question.top_k', '40'::jsonb, 'Only consider top K tokens (0=disabled)'),
('llm.question.min_p', '0.05'::jsonb, 'Minimum probability threshold relative to top token'),
('llm.question.stop', '["?"]'::jsonb, 'Stop on question mark to avoid duplication'),
('llm.question.trait_prompt', '"<trait>{trait_clause}</trait>\n<language>{language_code}</language>\n\nAsk a short yes/no question about this trait for a geography guessing game.\n\nRules:\n- Always ask about \\\"it\\\" (the place), not about the trait text.\n- If the trait contains a number (height, length, year, population, capacity, etc.), turn it into an approximate threshold or category question, not a vague one.\n- Never use specific names of places, people, events, or organizations.\n- Keep the meaning of the trait but use simple, everyday words.\n\nExamples:\n- \"Height is 330 meters including antenna\" \\u2192 \"Is it over 300 meters tall?\"\n- \"Built between 1910 and 1915\" \\u2192 \"Was it built in the early 20th century?\"\n- \"Can hold 60,000 spectators\" \\u2192 \"Can it hold over 50,000 people?\"\n\nOutput only the question text, ending with a single question mark."'::jsonb, 'Trait question prompt (turn 2+) - simplifies technical traits'),
('llm.question.region_prompt', '"<region>{region_name}</region>\n<language>{language_code}</language>\n\nAsk: Is it in {region_name}?\nOutput only the question."'::jsonb, 'Region question prompt (turn 2+) - uses "it" as subject'),
('llm.question.trait_prompt_turn1', '"<description>{user_description}</description>\n<trait>{trait_clause}</trait>\n<language>{language_code}</language>\n\nAsk a short yes/no question about this trait for a geography guessing game. Use the main noun phrase from the description (for example this tower, this church, this castle) as the subject instead of it.\n\nRules:\n- Use the subject from the description naturally (this tower, this castle, this building, etc.).\n- If the trait contains a number (height, length, year, population, capacity, etc.), convert it into an approximate threshold or category question, not a vague one.\n- Never use specific names of places, people, events, or organizations.\n- The question must be understandable to non-experts.\n\nExamples:\n- \"Height is 330 meters including antenna\" \\u2192 \"Is this tower over 300 meters tall?\"\n- \"Built between 1910 and 1915\" \\u2192 \"Was this building constructed in the early 20th century?\"\n- \"Can hold 60,000 spectators\" \\u2192 \"Can this venue hold over 50,000 people?\"\n\nOutput only the question text, ending with a single question mark."'::jsonb, 'Trait question prompt (turn 1) - simplifies technical traits, extracts noun'),
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
('scoring.temperature', '0.2'::jsonb, 'Temperature for probability softmax. Lower = sharper distribution'),
('scoring.trait_aggregation_temperature', '0.1'::jsonb, 'Temperature for trait similarity aggregation. Lower = best traits dominate'),
('scoring.initial_candidate_threshold', '0.3'::jsonb, 'Minimum aggregated trait score to become a candidate'),
('scoring.max_initial_candidates', '100'::jsonb, 'Maximum number of initial candidates'),
('scoring.min_display_probability', '0.1'::jsonb, 'Minimum probability to display candidate in UI (filters noise)'),

-- Trait matching (binary via place_traits, multiplicative adjustments)
('traits.boost_factor', '1.5'::jsonb, 'Score multiplier when trait ownership matches answer'),
('traits.penalty_factor', '0.4'::jsonb, 'Score multiplier when trait ownership contradicts answer'),

-- Question selection
('questions.min_split_quality', '0.3'::jsonb, 'Minimum acceptable split quality for questions'),
('questions.geographic_preference_threshold', '0.7'::jsonb, 'Geographic split quality to prefer over semantic'),
('questions.use_llm_generation', 'true'::jsonb, 'Use LLM to generate natural question text instead of templates');
