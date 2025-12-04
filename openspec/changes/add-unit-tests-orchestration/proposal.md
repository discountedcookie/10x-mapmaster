# Change: Add unit tests for orchestration functions

## Why

Current tests only cover isolated algorithm functions (softmax, thresholds, etc.) and basic game flow. **Orchestration functions that combine multiple components are untested**, which allows bugs like the column name ambiguity in `select_best_question` to slip through to runtime.

The bug discovered: `select_best_question` had `SELECT geographic_region_id` that conflicted with the return type's column name, only caught when the function was actually called during gameplay.

## What Changes

### New Test File: `test_orchestration.sql`

Comprehensive pgTAP tests for orchestration functions that should NOT call external services:

**Functions to test:**

- `select_best_question()` - Geographic vs semantic decision logic
- `get_geographic_questions()` - Geographic question ranking
- `get_semantic_questions()` - Semantic question ranking
- `decide_next_turn()` - Turn type decision (guess vs question)

**Testing approach:**

- Stub/mock LLM calls via `pgtap.version` test mode
- Use real database data (traits, places, regions)
- Test decision logic without external dependencies
- Verify correct function composition

### External Service Mocking

Functions that call external services will be tested with stubs:

- `generate_embedding()` → returns zero vector in test mode
- `generate_question_text()` → returns template in test mode
- `call_llm()` → bypassed in test mode (already works)

### Test Coverage

| Function                   | Test Scenarios                                                       |
| -------------------------- | -------------------------------------------------------------------- |
| `select_best_question`     | Geographic preference, semantic fallback, no questions available     |
| `get_geographic_questions` | Ranking by split quality, filtering asked questions, empty result    |
| `get_semantic_questions`   | Ranking by split quality, filtering asked questions, tie-breaking    |
| `decide_next_turn`         | Guess vs question decision, game-over detection, candidate filtering |

## Impact

- **Quality**: Catches orchestration bugs before gameplay
- **Maintenance**: Tests serve as documentation of component interaction
- **Speed**: Pure SQL tests (no browser/UI testing needed)
- **Safety**: Validates that algorithm functions are composed correctly

## Spec Changes

- No spec changes (testing is implementation detail)
