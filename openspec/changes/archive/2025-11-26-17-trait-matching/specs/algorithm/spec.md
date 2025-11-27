## ADDED Requirements

### Requirement: Trait Matching Adjustments

The system SHALL adjust candidate scores based on trait embeddings and answers.

#### Scenario: Match strength zones

- **WHEN** evaluating a trait against a place
- **THEN** match_strength is compared to strong/partial thresholds to classify match zone

#### Scenario: Score adjustments

- **WHEN** applying an answer
- **THEN** scores are boosted/penalized using power-law weighting per answer and match zone; not_sure makes no adjustment
