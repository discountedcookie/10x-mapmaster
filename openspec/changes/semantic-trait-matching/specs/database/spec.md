## ADDED Requirements

### Requirement: Game Log Table

The system SHALL store game state for replay and analysis.

#### Scenario: Table definition

- **WHEN** storing game logs
- **THEN** a `game_logic.game_log` table exists with:
  - `id`: UUID primary key
  - `session_id`: UUID FK to game_sessions
  - `turn_number`: INTEGER
  - `candidates_snapshot`: JSONB (candidates with scores at this turn)
  - `question_type`: question_type
  - `trait_id`: UUID (nullable, for semantic questions)
  - `region_id`: UUID (nullable, for geographic questions)
  - `answer`: answer_value (nullable, null for initial state)
  - `created_at`: TIMESTAMPTZ

#### Scenario: Indexing

- **WHEN** querying game logs
- **THEN** indexes exist on (session_id), (session_id, turn_number)

### Requirement: Model Parameters Storage

The system SHALL store tunable model parameters.

#### Scenario: Ordinal model parameters

- **WHEN** storing ordinal model config
- **THEN** config keys exist for:
  - `model.delta_0`: NUMERIC (lower threshold)
  - `model.delta_1`: NUMERIC (upper threshold)

#### Scenario: Embedding-parameterized parameters

- **WHEN** storing trait parameter config
- **THEN** config keys exist for:
  - `model.w_alpha`: JSON array (R^d vector)
  - `model.w_m`: JSON array (R^d vector)
  - `model.b_alpha`: NUMERIC scalar
  - `model.b_m`: NUMERIC scalar

#### Scenario: Metric parameters

- **WHEN** storing learned metric config
- **THEN** config keys exist for:
  - `metric.type`: 'cosine' | 'diagonal' | 'low_rank'
  - `metric.W_diagonal`: JSON array (d weights) — for diagonal
  - `metric.W_matrix`: JSON 2D array (k×d) — for low-rank

### Requirement: Transformed Embeddings

The system MAY support transformed embeddings if learned metric is deployed.

#### Scenario: Transformed storage

- **WHEN** using learned metric W with pre-computation
- **THEN** embeddings table has `transformed` column (vector(k))
- **AND** transformed = W @ original_embedding

#### Scenario: On-the-fly transformation

- **WHEN** metric W is small or frequently updated
- **THEN** transformation is applied at query time

### Requirement: Ordinal Response Functions

The system SHALL provide functions for ordinal response model.

#### Scenario: Probability computation

- **WHEN** computing response probabilities
- **THEN** function `ordinal_prob(eta, delta_0, delta_1, answer)` returns P(answer | eta)
- **AND** handles 'yes', 'not_sure', 'no'
- **AND** probabilities sum to 1

#### Scenario: Trait parameter computation

- **WHEN** computing per-trait parameters
- **THEN** function `compute_trait_params(trait_id)` returns (alpha_q, m_q)
- **AND** uses stored w_alpha, w_m, b_alpha, b_m
- **AND** applies to trait's embedding

### Requirement: Similarity Functions

The system SHALL support configurable similarity metrics.

#### Scenario: Raw cosine

- **WHEN** metric.type = 'cosine'
- **THEN** `trait_place_similarity(trait_id, place_id)` uses raw cosine

#### Scenario: Diagonal metric

- **WHEN** metric.type = 'diagonal'
- **THEN** apply feature reweighting before cosine
- **AND** sim = Σ_j w_j² · e_place[j] · e_trait[j] / norm

#### Scenario: Low-rank metric

- **WHEN** metric.type = 'low_rank'
- **THEN** use transformed embeddings or apply W at query time

### Requirement: Algorithm Inspection Views

The system SHALL provide views for inspecting algorithm state.

#### Scenario: Algorithm state view

- **THEN** `algorithm_state` view shows candidates with:
  - place_id, name, log_score, probability
  - similarity to current question trait
  - how score changed from previous turn

#### Scenario: Trait evaluation view

- **THEN** `trait_evaluation` view shows traits with:
  - trait_id, clause, category
  - computed alpha_q, m_q
  - information_gain for current candidate set

### Requirement: Game Replay Function

The system SHALL support game replay.

#### Scenario: Replay function

- **WHEN** calling `replay_game(session_id)`
- **THEN** returns table of (turn_number, candidates_snapshot, question, answer)
- **AND** ordered by turn_number

## REMOVED Requirements

The following from the previous version are removed:

- Calibration data table (calibration_log)
- Diagnostic fields (distractor_similarities, posterior_entropy)
- Cold-start split infrastructure
