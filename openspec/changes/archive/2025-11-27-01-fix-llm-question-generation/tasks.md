## 1. Database Layer

- [x] 1.1 Create `http_call_edge_function()` wrapper function using pg_net/http extension
- [x] 1.2 Create `generate_question_text(trait_id, region_id, language_code)` function that calls `call-llm`
- [x] 1.3 Modify `get_semantic_questions()` to return only trait metadata (remove question_text generation)
- [x] 1.4 Modify `get_geographic_questions()` to return only region metadata (remove question_text generation)
- [x] 1.5 Update `get_question()` to call `generate_question_text()` after selection

## 2. Edge Function Updates

- [x] 2.1 Use existing `call-llm` with text prompt (no special mode needed)
- [x] 2.2 Prompt template built in `generate_question_text()` function
- [x] 2.3 Config read from `game_logic.config` via `call_llm_api()`

## 3. Configuration

- [x] 3.1 Add `questions.use_llm_generation` config flag (default: true)
- [x] 3.2 Uses existing `llm.model`, `llm.temperature` config values

## 4. Testing

- [x] 4.1 Tested manually - generates natural questions
- [x] 4.2 Fallback works - returns template if LLM fails
- [x] 4.3 All 78 pgTAP tests pass
