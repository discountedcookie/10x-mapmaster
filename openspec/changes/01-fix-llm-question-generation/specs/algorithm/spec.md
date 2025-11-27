## MODIFIED Requirements

### Requirement: Question Selection

The system SHALL choose the next question based on split quality, considering geographic and semantic options, and generate natural language question text via LLM.

#### Scenario: Geographic preference

- **WHEN** a geographic question meets the geographic preference threshold
- **THEN** it is chosen over semantic options

#### Scenario: Semantic selection

- **WHEN** no geographic option qualifies
- **THEN** the semantic trait with highest split_quality is chosen; ties broken by description similarity

#### Scenario: Fallback

- **WHEN** no option meets min_split_quality
- **THEN** the best available question is still selected

#### Scenario: LLM question text generation

- **WHEN** a trait or region is selected algorithmically
- **THEN** the LLM generates natural language question text for that selection (no hardcoded templates)

#### Scenario: Question text fallback

- **WHEN** LLM is unavailable or errors
- **THEN** a simple fallback template is used and the error is logged
