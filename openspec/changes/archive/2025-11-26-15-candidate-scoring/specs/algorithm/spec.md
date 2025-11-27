## ADDED Requirements

### Requirement: Candidate Scoring

The system SHALL score places by semantic similarity and produce probabilities.

#### Scenario: Similarity and softmax

- **WHEN** scoring candidates
- **THEN** similarity is computed between description and place embeddings and converted to probabilities via temperature-scaled softmax

#### Scenario: Threshold and cap

- **WHEN** selecting initial candidates
- **THEN** scores below a threshold are excluded and results are capped per configured limit
