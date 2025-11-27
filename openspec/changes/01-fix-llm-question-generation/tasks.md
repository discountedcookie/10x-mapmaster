## 1. Database Layer

- [x] 1.1 Create `http_call_edge_function()` wrapper function using pg_net/http extension
- [x] 1.2 Create `generate_question_text(trait_id, region_id, language_code)` function that calls `call-llm`
- [x] 1.3 Modify `get_semantic_questions()` to return only trait metadata (remove question_text generation)
- [x] 1.4 Modify `get_geographic_questions()` to return only region metadata (remove question_text generation)
- [x] 1.5 Update `get_question()` to call `generate_question_text()` after selection

## 2. Edge Function Updates

- [ ] 2.1 Update `call-llm` to accept "question_generation" mode
- [ ] 2.2 Add prompt template for question phrasing (simpler than current selection prompt)
- [ ] 2.3 Add config for model/temperature from `game_logic.config`

## 3. Configuration

- [ ] 3.1 Add `llm.question.prompt` to seed data with question phrasing prompt
- [ ] 3.2 Add `llm.question.model`, `llm.question.temperature` config values

## 4. Testing

- [ ] 4.1 Add pgTAP test for `generate_question_text()` with mocked response
- [ ] 4.2 Test fallback behavior when LLM unavailable
- [ ] 4.3 E2E test: verify questions are natural language, not templates
