# Algorithm Specification

## Purpose

Define the mathematical formulas and decision logic for candidate scoring, confidence calculation, trait matching, and question selection. All algorithm logic runs in PostgreSQL.

---

## Requirements

### Requirement: Initial Candidate Scoring

The system SHALL score places by semantic similarity to player description.

#### Scenario: Calculate raw score

- **WHEN** scoring a place against description
- **THEN** raw_score = similarity(place.embedding, description.embedding)
- **AND** uses pgvector inner product on normalized embeddings

#### Scenario: Select initial candidates

- **WHEN** starting a game
- **THEN** gets places with raw_score >= initial_candidate_threshold
- **AND** orders by raw_score descending
- **AND** limits to max_initial_candidates

---

### Requirement: Probability Distribution

The system SHALL convert scores to probabilities via softmax.

#### Scenario: Calculate probabilities

- **WHEN** scores need probability distribution
- **THEN** P(place_i) = exp(score_i / temperature) / sum(exp(score_j / temperature))

#### Scenario: Temperature effect

- **WHEN** lower temperature used
- **THEN** distribution is sharper (amplifies differences)
- **AND** higher temperature creates flatter distribution

---

### Requirement: Confidence Decision Metrics

The system SHALL use three metrics to decide when to guess.

#### Scenario: Top probability metric

- **WHEN** evaluating confidence
- **THEN** top_prob = max(P(place_i))

#### Scenario: Margin metric

- **WHEN** evaluating confidence
- **THEN** margin = P(top) - P(second)

#### Scenario: Entropy metric

- **WHEN** evaluating confidence
- **THEN** entropy = -sum(P(i) \* ln(P(i)))
- **AND** normalized_entropy = entropy / ln(candidate_count)

---

### Requirement: Guess Decision Rule

The system SHALL guess only when all three thresholds pass.

#### Scenario: All thresholds pass

- **WHEN** top_prob >= threshold AND margin >= threshold AND entropy <= threshold
- **THEN** system guesses top candidate

#### Scenario: Any threshold fails

- **WHEN** any threshold not met
- **THEN** system asks another question

#### Scenario: Edge cases

- **WHEN** single candidate remains
- **THEN** automatic guess
- **WHEN** all scores identical
- **THEN** all thresholds fail, ask question

---

### Requirement: Trait Match Scoring

The system SHALL calculate match strength between candidates and traits.

#### Scenario: Calculate match strength

- **WHEN** evaluating trait match
- **THEN** match_strength = similarity(place.embedding, trait.embedding)

#### Scenario: Match zones

- **WHEN** match_strength >= strong_threshold
- **THEN** STRONG match
- **WHEN** match_strength >= partial_threshold
- **THEN** PARTIAL match
- **OTHERWISE** WEAK match

---

### Requirement: Score Adjustment

The system SHALL adjust scores based on answers using power-law scaling.

#### Scenario: Calculate adjustment magnitude

- **WHEN** applying answer
- **THEN** magnitude = base_weight \* match_strength^beta

#### Scenario: Yes answer to strong/partial match

- **WHEN** player answers YES and place has strong/partial match
- **THEN** positive adjustment (boost)

#### Scenario: Yes answer to weak match

- **WHEN** player answers YES and place has weak match
- **THEN** negative adjustment (penalty - lacks affirmed trait)

#### Scenario: No answer to strong/partial match

- **WHEN** player answers NO and place has strong/partial match
- **THEN** negative adjustment (penalty - has denied trait)

#### Scenario: No answer to weak match

- **WHEN** player answers NO and place has weak match
- **THEN** positive adjustment (boost - correctly lacks denied trait)

#### Scenario: Not sure answer

- **WHEN** player answers NOT SURE
- **THEN** no score adjustment

---

### Requirement: Question Split Quality

The system SHALL evaluate questions by how evenly they split candidates.

#### Scenario: Calculate fraction matching

- **WHEN** evaluating potential question
- **THEN** fraction = count(match >= threshold) / total_candidates

#### Scenario: Calculate split quality

- **WHEN** fraction calculated
- **THEN** split_quality = 1 - |0.5 - fraction|
- **AND** 0.5 fraction = 1.0 quality (perfect)
- **AND** 0.0 or 1.0 fraction = 0.5 quality (useless)

---

### Requirement: Question Selection Algorithm

The system SHALL select the most discriminating question.

#### Scenario: Select best question

- **WHEN** choosing next question
- **THEN** get traits not yet asked in session
- **AND** calculate split_quality for each
- **AND** filter by min_split_quality
- **AND** select highest split_quality

#### Scenario: Tiebreaker

- **WHEN** multiple traits have equal split_quality
- **THEN** prefer trait most similar to player description

#### Scenario: No good questions

- **WHEN** no trait meets min_split_quality
- **THEN** select best available anyway

---

### Requirement: Geographic vs Semantic Questions

The system SHALL choose between geographic and semantic questions.

#### Scenario: Prefer geographic

- **WHEN** best geographic split >= geographic_preference_threshold
- **THEN** ask geographic question (binary PostGIS filter)

#### Scenario: Fall back to semantic

- **WHEN** geographic split below threshold
- **THEN** ask semantic question with best split_quality

---

### Requirement: Spatial Filtering

The system SHALL filter candidates via PostGIS for geographic answers.

#### Scenario: Geographic YES answer

- **WHEN** player confirms region
- **THEN** candidates = filter(ST_Contains(region, place.geom))

#### Scenario: Geographic NO answer

- **WHEN** player denies region
- **THEN** candidates = filter(NOT ST_Contains(region, place.geom))

---

### Requirement: Configuration Parameters

The system SHALL read all algorithm parameters from config tables.

#### Scenario: Scoring parameters

- **WHEN** scoring candidates
- **THEN** reads temperature, initial_candidate_threshold, max_initial_candidates from config

#### Scenario: Confidence parameters

- **WHEN** deciding to guess
- **THEN** reads top_prob_threshold, margin_threshold, entropy_threshold from config

#### Scenario: Trait parameters

- **WHEN** matching traits
- **THEN** reads strong_match_threshold, partial_match_threshold, base_weight, beta from config

#### Scenario: Question parameters

- **WHEN** selecting questions
- **THEN** reads min_split_quality, match_threshold, geographic_preference_threshold from config
