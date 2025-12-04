## ADDED Requirements

### Requirement: Game Turn Table

The system SHALL store the current pending turn in a dedicated table with typed columns.

#### Scenario: Turn table structure

- **WHEN** the `game_turn` table is created
- **THEN** it has columns:
  - `session_id` (uuid, PK, FK to game_sessions ON DELETE CASCADE)
  - `action` (enum: 'question', 'guess')
  - `question_text` (text, nullable)
  - `question_type` (enum: 'semantic', 'geographic', nullable)
  - `trait_id` (uuid, nullable, FK to traits)
  - `geographic_region_id` (uuid, nullable, FK to geographic_regions)
  - `guess_place_id` (uuid, nullable, FK to places)
  - `guess_place_name` (text, nullable)
  - `created_at` (timestamptz, default now())

#### Scenario: Turn lifecycle

- **WHEN** a game starts
- **THEN** a `game_turn` row is created with the first question/guess
- **WHEN** a turn is played
- **THEN** the `game_turn` row is updated with the next action (or deleted if game ends)
- **WHEN** a game ends (won, gave up, max turns)
- **THEN** the `game_turn` row is deleted

#### Scenario: Constraints

- **WHEN** action = 'question'
- **THEN** question_text is NOT NULL and exactly one of (trait_id, geographic_region_id) is NOT NULL
- **WHEN** action = 'guess'
- **THEN** guess_place_id and guess_place_name are NOT NULL

#### Scenario: RLS policy

- **WHEN** a user queries `game_turn`
- **THEN** they can only see rows where the parent `game_sessions.user_id = auth.uid()`
- **AND** policy is enforced via join or subquery to game_sessions

### Requirement: Game Session Candidates Table

The system SHALL store current candidates in a dedicated table with typed columns.

#### Scenario: Candidates table structure

- **WHEN** the `game_session_candidates` table is created
- **THEN** it has columns:
  - `session_id` (uuid, FK to game_sessions ON DELETE CASCADE)
  - `place_id` (uuid, FK to places)
  - `probability` (double precision, NOT NULL)
  - `description_similarity` (double precision)
  - `affirmed_trait_similarity` (double precision)
  - `denied_trait_similarity` (double precision)
  - `geographic_distance` (double precision)
  - PRIMARY KEY (session_id, place_id)

#### Scenario: Candidates lifecycle

- **WHEN** a game starts
- **THEN** initial candidates are inserted into `game_session_candidates`
- **WHEN** a turn is played
- **THEN** candidates are updated (scores adjusted, eliminated places removed)
- **WHEN** a game ends
- **THEN** candidates remain for potential history/analytics (not deleted immediately)

#### Scenario: Indexes

- **WHEN** querying candidates for a session
- **THEN** an index on `session_id` supports efficient lookup
- **WHEN** ordering by probability
- **THEN** an index on `(session_id, probability DESC)` supports efficient ordering

#### Scenario: RLS policy

- **WHEN** a user queries `game_session_candidates`
- **THEN** they can only see rows where the parent `game_sessions.user_id = auth.uid()`

### Requirement: Game Sessions Cleanup

The system SHALL remove the `next_turn` JSONB column from `game_sessions`.

#### Scenario: Column removal

- **WHEN** the schema migration runs
- **THEN** `game_sessions.next_turn` column is dropped
- **AND** status continues to be COMPUTED in `game_session_state` view (not stored)

#### Scenario: Migration strategy

- **WHEN** the migration runs in development
- **THEN** existing `next_turn` data is NOT migrated (clean slate)
- **AND** any in-progress games are effectively reset

### Requirement: Historical Snapshot Retention

The system SHALL retain the existing `game_answers.candidates` JSONB column for historical audit purposes.

#### Scenario: History vs current state

- **WHEN** recording an answer
- **THEN** `game_answers.candidates` stores a JSONB snapshot of candidates at answer time (historical)
- **AND** `game_session_candidates` table holds the CURRENT candidates (typed, active)
- **AND** frontend ONLY reads from `game_session_candidates` for current state

## MODIFIED Requirements

### Requirement: Game Session State View

The system SHALL expose game state via a view with typed columns instead of JSONB blobs.

#### Scenario: Flat typed columns

- **WHEN** querying `game_session_state`
- **THEN** it returns typed columns:
  - `session_id` (uuid)
  - `description` (text)
  - `status` (game_session_status enum)
  - `action` (turn_action enum, nullable - from game_turn)
  - `question_text` (text, nullable)
  - `question_type` (question_type enum, nullable)
  - `trait_id` (uuid, nullable - for semantic questions)
  - `geographic_region_id` (uuid, nullable - for geographic questions)
  - `guess_place_id` (uuid, nullable)
  - `guess_place_name` (text, nullable)
  - `place_id` (uuid, nullable - final place when won/submitted)
  - `place_name` (text, nullable)
  - `place_lat` (double precision, nullable)
  - `place_lng` (double precision, nullable)
  - `question_count` (bigint)
- **AND** no JSONB columns are returned

#### Scenario: RLS inheritance

- **WHEN** querying the view
- **THEN** RLS from `game_sessions` is applied
- **AND** users only see their own sessions

### Requirement: Get Session Candidates Function

The system SHALL provide a typed function for fetching candidates.

#### Scenario: Function signature

- **WHEN** calling `get_session_candidates(p_session_id uuid)`
- **THEN** it returns `TABLE(id uuid, name text, lat double precision, lng double precision, probability double precision, description_similarity double precision)`
- **AND** Supabase generates TypeScript types for the return columns
- **AND** no JSONB columns are returned (geometry fetched separately if needed)

#### Scenario: Join with places

- **WHEN** fetching candidates
- **THEN** the function joins `game_session_candidates` with `places` to include place details
- **AND** orders by probability DESC

#### Scenario: Security

- **WHEN** calling the function
- **THEN** it is SECURITY DEFINER with hardened search_path
- **AND** it validates that the session belongs to the calling user
