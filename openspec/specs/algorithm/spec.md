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

