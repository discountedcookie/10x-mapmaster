## MODIFIED Requirements

### Requirement: Trait Matching Adjustments

The system SHALL adjust candidate scores based on trait embedding similarity and answers.

#### Scenario: Match strength zones

- **WHEN** evaluating a trait against a place
- **THEN** match_strength is computed as embedding similarity (pgvector) and compared to strong/partial thresholds to classify match zone

#### Scenario: Score adjustments

- **WHEN** applying an answer
- **THEN** scores are boosted/penalized using power-law weighting per answer and match zone; not_sure makes no adjustment

#### Scenario: Embedding-based matching

- **WHEN** determining if a place has a trait
- **THEN** similarity is calculated via pgvector operators (no join table fallback)
