## ADDED Requirements

### Requirement: Confidence Decision Rule

The system SHALL decide to guess or ask based on configured confidence metrics.

#### Scenario: Guess decision

- **WHEN** top_prob, margin, and normalized_entropy meet configured thresholds
- **THEN** the system chooses to guess the top candidate

#### Scenario: Ask decision

- **WHEN** thresholds are not all met or distribution is ambiguous
- **THEN** the system chooses to ask another question
