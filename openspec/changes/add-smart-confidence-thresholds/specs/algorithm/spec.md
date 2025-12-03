## MODIFIED Requirements

### Requirement: Confidence Normalization

The system SHALL normalize candidate confidence scores to sum to 100% using softmax.

#### Scenario: After initial candidate selection

- **WHEN** candidates are selected from `get_candidates()`
- **THEN** confidence scores are normalized via softmax with configurable temperature
- **AND** all candidate confidences sum to 1.0 (100%)

#### Scenario: After geographic filtering

- **WHEN** a geographic question is answered and candidates are filtered
- **THEN** remaining candidates are re-normalized via softmax
- **AND** confidences sum to 1.0 among remaining candidates

#### Scenario: After semantic adjustment

- **WHEN** a semantic question is answered and scores are adjusted
- **THEN** candidates are re-normalized via softmax
- **AND** confidences sum to 1.0

### Requirement: Dynamic Guess Threshold

The system SHALL use a dynamic threshold for guessing that adapts based on turn number, candidate count, and margin.

#### Scenario: Turn-based interpolation

- **WHEN** calculating whether to guess
- **THEN** base threshold interpolates linearly from `guess_threshold_max` (turn 0) to `guess_threshold_min` (final turn)

#### Scenario: Candidate count bonus

- **WHEN** candidate count is at or below `candidate_low_threshold`
- **THEN** reduce threshold by `candidate_bonus`

#### Scenario: Margin bonus

- **WHEN** margin between top two candidates is at or above `margin_high_threshold`
- **THEN** reduce threshold by `margin_bonus`

#### Scenario: Additive stacking

- **WHEN** both candidate count and margin bonuses apply
- **THEN** both adjustments are applied additively

#### Scenario: Safety rails

- **WHEN** calculating final threshold
- **THEN** result is clamped between `threshold_floor` and `threshold_ceiling`

#### Scenario: Guess decision

- **WHEN** top candidate probability exceeds the dynamic threshold
- **THEN** the system guesses instead of asking another question

## ADDED Requirements

### Requirement: Smart Threshold Configuration

The system SHALL expose configuration knobs for all threshold parameters.

#### Scenario: Config keys exist

- **WHEN** the game logic reads threshold configuration
- **THEN** the following keys are available in `game_logic.config`:
  - `confidence.guess_threshold_max` (default 0.90)
  - `confidence.guess_threshold_min` (default 0.60)
  - `confidence.threshold_floor` (default 0.50)
  - `confidence.threshold_ceiling` (default 0.95)
  - `confidence.candidate_low_threshold` (default 3)
  - `confidence.candidate_bonus` (default 0.10)
  - `confidence.margin_high_threshold` (default 0.25)
  - `confidence.margin_bonus` (default 0.10)

## REMOVED Requirements

### Requirement: Static Threshold (REMOVED)

The static `confidence.top_prob_threshold`, `confidence.margin_threshold`, and `confidence.entropy_threshold` config keys are removed. Replaced by the dynamic threshold system.
