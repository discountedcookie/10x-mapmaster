# algorithm Specification

## Purpose

Specifies the algorithms for candidate filtering, scoring, confidence decisions, trait matching, and question selection. All algorithm logic executes in PostgreSQL functions within the `game_logic` schema.
## Requirements
### Requirement: Geographic Candidate Filtering

The system SHALL filter candidate places by geographic regions for geographic questions.

#### Scenario: Region inclusion

- **WHEN** an answer affirms a region
- **THEN** candidates are filtered to places whose geometry is within the region

#### Scenario: Region exclusion

- **WHEN** an answer denies a region
- **THEN** candidates exclude places contained in that region

#### Scenario: Performance support

- **WHEN** executing filters
- **THEN** appropriate GIST indexes on place geometry are used

### Requirement: Candidate Scoring

The system SHALL score places using softmax-weighted aggregation of trait similarities and produce probabilities.

#### Scenario: Trait similarity aggregation

- **WHEN** scoring a candidate place
- **THEN** similarity is computed between description embedding and each of the place's trait embeddings, then aggregated using softmax-weighted average with configurable temperature

#### Scenario: Softmax weighting

- **WHEN** aggregating trait similarities
- **THEN** weights are computed as exp(sim/τ)/Σexp(sim/τ) where τ is the aggregation temperature, giving high-similarity traits more influence

#### Scenario: Probability distribution

- **WHEN** converting scores to probabilities
- **THEN** raw scores are converted via temperature-scaled softmax for confidence calculation

#### Scenario: Threshold and cap

- **WHEN** selecting initial candidates
- **THEN** aggregated scores below a threshold are excluded and results are capped per configured limit

### Requirement: Confidence Decision Rule

The system SHALL decide to guess or ask based on configured confidence metrics.

#### Scenario: Guess decision

- **WHEN** top_prob, margin, and normalized_entropy meet configured thresholds
- **THEN** the system chooses to guess the top candidate

#### Scenario: Ask decision

- **WHEN** thresholds are not all met or distribution is ambiguous
- **THEN** the system chooses to ask another question

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

### Requirement: Question Selection

The system SHALL choose the next question based on split quality calculated from place_traits relationships, considering geographic and semantic options, and generate natural language question text via LLM.

#### Scenario: Split quality calculation

- **WHEN** evaluating a trait for question selection
- **THEN** split quality is calculated by counting how many candidates have the trait via place_traits table, measuring how close to 50/50 split

#### Scenario: Geographic preference

- **WHEN** a geographic question meets the geographic preference threshold
- **THEN** it is chosen over semantic options

#### Scenario: Semantic selection

- **WHEN** no geographic option qualifies
- **THEN** the semantic trait with highest split_quality is chosen; ties broken by description-to-trait embedding similarity

#### Scenario: Fallback

- **WHEN** no option meets min_split_quality
- **THEN** the best available question is still selected

#### Scenario: LLM question text generation

- **WHEN** a trait or region is selected algorithmically
- **THEN** the LLM generates natural language question text for that selection (no hardcoded templates)

#### Scenario: Question text fallback

- **WHEN** LLM is unavailable or errors
- **THEN** a simple fallback template is used and the error is logged

### Requirement: Algorithm Evaluation Tooling

The system SHALL document and use supported mechanisms for evaluating and testing algorithm behavior without relying on legacy ad-hoc scripts.

#### Scenario: Legacy scripts removed

- **WHEN** contributors look for algorithm evaluation tooling
- **THEN** they do not find legacy scripts like scripts/test-algorithm-configs.ts referenced as part of the supported workflow.

#### Scenario: Documented workflow

- **WHEN** evaluating or testing algorithm behavior
- **THEN** contributors follow the workflows and tooling described in the algorithm and operations specs instead of deprecated scripts.

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

