## MODIFIED Requirements

### Requirement: Response Model

The system SHALL model answers as **ordinal** (YES / NOT_SURE / NO), not binary.

#### Scenario: Ordinal response probabilities

- **GIVEN** latent trait applicability η = α_q · (sim(i, q) - m_q)
- **THEN** response probabilities follow the graded response model:
  - P(NO | η) = 1 - σ(η - δ₀)
  - P(NOT_SURE | η) = σ(η - δ₀) - σ(η - δ₁)
  - P(YES | η) = σ(η - δ₁)
- **AND** δ₀ < δ₁ are learned thresholds
- **AND** NOT_SURE is informative, not noise

### Requirement: Embedding-Parameterized Trait Parameters

The system SHALL predict per-trait discrimination (α_q) and difficulty (m_q) from trait embeddings.

#### Scenario: Parameter prediction

- **WHEN** computing response probabilities for trait q
- **THEN** α*q = w*α · e*q + b*α (discrimination from embedding)
- **AND** m_q = w_m · e_q + b_m (difficulty from embedding)
- **AND** w*α, w_m, b*α, b_m are tunable parameters

#### Scenario: New traits work automatically

- **GIVEN** a new trait not seen before
- **THEN** (α_q, m_q) are computed from its embedding
- **AND** the trait can be used immediately without special calibration

### Requirement: Learned Metric (Optional)

The system MAY learn a task-specific similarity metric instead of raw cosine.

#### Scenario: Metric transformation

- **WHEN** computing similarity between place and trait
- **AND** metric.type is not 'cosine'
- **THEN** sim_W(i, q) = normalized dot product of (W·e_i) and (W·e_q)
- **AND** W is configurable (diagonal or low-rank)

#### Scenario: Metric selection

- **WHEN** raw cosine works well enough
- **THEN** metric.type = 'cosine' and no transformation is applied

### Requirement: Score Updates

The system SHALL update place scores using the full ordinal likelihood.

#### Scenario: Log-space update

- **WHEN** an answer Y ∈ {YES, NOT_SURE, NO} is given
- **THEN** for each place i: log_score[i] += ln(P(Y | η(i, q)))
- **AND** NOT_SURE contributes likelihood (not zero)
- **AND** probabilities are computed via softmax over log_scores

### Requirement: Information Gain

The system SHALL compute information gain over all three response outcomes.

#### Scenario: Three-outcome IG

- **WHEN** selecting next question
- **THEN** IG(q) = H(now) - E[H(after)]
- **AND** E[H(after)] = Σ\_{y ∈ {YES, NOT_SURE, NO}} P(Y=y) · H(posterior | Y=y)
- **AND** traits where NOT_SURE is informative have value

## ADDED Requirements

### Requirement: Algorithm Inspection

The system SHALL provide views for inspecting algorithm state.

#### Scenario: Candidate state view

- **WHEN** debugging algorithm behavior
- **THEN** a view shows current candidates with scores, probabilities, and similarities

#### Scenario: Trait evaluation view

- **WHEN** understanding question selection
- **THEN** a view shows traits with their (α_q, m_q) and information gain

#### Scenario: Turn impact view

- **WHEN** analyzing game progression
- **THEN** a view shows how each turn changed candidate rankings

### Requirement: Game Logging

The system SHALL log game state for replay and analysis.

#### Scenario: Per-turn logging

- **WHEN** a turn is played
- **THEN** the current state is logged (candidates, scores, question, answer)

#### Scenario: Game replay

- **WHEN** analyzing a past game
- **THEN** a function returns turn-by-turn state progression

### Requirement: Batch Testing

The system SHALL support automated batch testing.

#### Scenario: Known place testing

- **GIVEN** a list of (description, expected_place) pairs
- **WHEN** running batch tests
- **THEN** each game is played automatically
- **AND** results include: turns to guess, correct?, score progression

## REMOVED Requirements

The following from the previous version are removed:

- Model Comparison Protocol (M0/M1/M2/M3 formal comparison)
- Cold-start evaluation protocol
- Diagnostic Protocol (residual analysis, human behavior assumptions)
- Statistical validation gates (Brier scores, p-values)
- Calibration curves and reliability analysis
