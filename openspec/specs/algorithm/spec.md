# algorithm Specification

## Purpose
TBD - created by archiving change 08-geographic-filtering. Update Purpose after archive.
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

The system SHALL score places by semantic similarity and produce probabilities.

#### Scenario: Similarity and softmax

- **WHEN** scoring candidates
- **THEN** similarity is computed between description and place embeddings and converted to probabilities via temperature-scaled softmax

#### Scenario: Threshold and cap

- **WHEN** selecting initial candidates
- **THEN** scores below a threshold are excluded and results are capped per configured limit

### Requirement: Confidence Decision Rule

The system SHALL decide to guess or ask based on configured confidence metrics.

#### Scenario: Guess decision

- **WHEN** top_prob, margin, and normalized_entropy meet configured thresholds
- **THEN** the system chooses to guess the top candidate

#### Scenario: Ask decision

- **WHEN** thresholds are not all met or distribution is ambiguous
- **THEN** the system chooses to ask another question

### Requirement: Trait Matching Adjustments

The system SHALL adjust candidate scores based on trait embeddings and answers.

#### Scenario: Match strength zones

- **WHEN** evaluating a trait against a place
- **THEN** match_strength is compared to strong/partial thresholds to classify match zone

#### Scenario: Score adjustments

- **WHEN** applying an answer
- **THEN** scores are boosted/penalized using power-law weighting per answer and match zone; not_sure makes no adjustment

### Requirement: Question Selection

The system SHALL choose the next question based on split quality, considering geographic and semantic options.

#### Scenario: Geographic preference

- **WHEN** a geographic question meets the geographic preference threshold
- **THEN** it is chosen over semantic options

#### Scenario: Semantic selection

- **WHEN** no geographic option qualifies
- **THEN** the semantic trait with highest split_quality is chosen; ties broken by description similarity

#### Scenario: Fallback

- **WHEN** no option meets min_split_quality
- **THEN** the best available question is still selected

