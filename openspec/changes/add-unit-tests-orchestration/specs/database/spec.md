## ADDED Requirements

### Requirement: Orchestration Function Testing

The system SHALL have comprehensive unit tests for orchestration functions that combine algorithm components, without calling external services.

#### Scenario: Question selection tested

- **WHEN** testing `select_best_question()` function
- **THEN** geographic vs semantic decision logic is verified with real database data
- **AND** no LLM or embedding service calls are made

#### Scenario: Turn decision tested

- **WHEN** testing `decide_next_turn()` function
- **THEN** guess vs question decision is verified with dynamic threshold calculation
- **AND** game-over and candidate-depletion scenarios are covered

#### Scenario: Geographic question ranking tested

- **WHEN** testing `get_geographic_questions()` function
- **THEN** split quality ranking and already-asked filtering are verified
- **AND** results respect geographic level hierarchy

#### Scenario: Semantic question ranking tested

- **WHEN** testing `get_semantic_questions()` function
- **THEN** split quality ranking and already-asked filtering are verified
- **AND** tie-breaking by embedding similarity works correctly
