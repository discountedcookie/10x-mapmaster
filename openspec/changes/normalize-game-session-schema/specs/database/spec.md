## ADDED Requirements

### Requirement: Game Turns Table

The system SHALL store all turns (historical and current pending) in a dedicated table with typed columns.

#### Scenario: Turns table structure

- **WHEN** the `game_turns` table is created
- **THEN** it has columns:
  - `id` (uuid, PK, default gen_random_uuid())
  - `session_id` (uuid, FK to game_sessions ON DELETE CASCADE)
  - `turn_number` (integer, NOT NULL)
  - `action` (turn_action enum: 'question', 'guess')
  - `question_text` (text, nullable)
  - `question_type` (question_type enum: 'semantic', 'geographic', nullable)
  - `trait_id` (uuid, nullable, FK to traits)
  - `geographic_region_id` (uuid, nullable, FK to geographic_regions)
  - `guess_place_id` (uuid, nullable, FK to places)
  - `guess_place_name` (text, nullable)
  - `answer` (answer_value enum, nullable - NULL means pending)
  - `created_at` (timestamptz, default now())
  - `answered_at` (timestamptz, nullable)
- **AND** a UNIQUE constraint exists on `(session_id, turn_number)`

#### Scenario: Turn lifecycle

- **WHEN** a game starts
- **THEN** the first `game_turns` row is created with `turn_number = 1` and `answer = NULL`
- **WHEN** a turn is answered
- **THEN** the current turn's `answer` and `answered_at` are set
- **AND** if the game continues, a new turn row is inserted with `turn_number + 1` and `answer = NULL`
- **WHEN** a game ends (won, gave up, max turns)
- **THEN** no new turn is created; the last turn has `answer` set (or remains NULL for give_up)

#### Scenario: Current turn identification

- **WHEN** determining the current pending turn
- **THEN** it is the row where `answer IS NULL` for that session
- **AND** there is at most one such row per session

#### Scenario: Constraints

- **WHEN** action = 'question'
- **THEN** question_text is NOT NULL and exactly one of (trait_id, geographic_region_id) is NOT NULL
- **WHEN** action = 'guess'
- **THEN** guess_place_id and guess_place_name are NOT NULL

#### Scenario: RLS policy

- **WHEN** a user queries `game_turns`
- **THEN** they can only see rows where the parent `game_sessions.user_id = auth.uid()`
- **AND** policy is enforced via join or subquery to game_sessions

### Requirement: Game Turn Candidates Table

The system SHALL store candidates at each turn in a dedicated table with typed columns.

#### Scenario: Candidates table structure

- **WHEN** the `game_turn_candidates` table is created
- **THEN** it has columns:
  - `turn_id` (uuid, FK to game_turns ON DELETE CASCADE)
  - `place_id` (uuid, FK to places)
  - `probability` (double precision, NOT NULL)
  - `description_similarity` (double precision)
  - `affirmed_trait_similarity` (double precision)
  - `denied_trait_similarity` (double precision)
  - `geographic_distance` (double precision)
  - PRIMARY KEY (turn_id, place_id)

#### Scenario: Candidates lifecycle

- **WHEN** a new turn is created
- **THEN** candidates are copied/computed into `game_turn_candidates` for that turn
- **WHEN** querying candidates for the current turn
- **THEN** join `game_turns` (where answer IS NULL) with `game_turn_candidates`
- **WHEN** querying historical candidates
- **THEN** join `game_turns` (by turn_number) with `game_turn_candidates` to show evolution

#### Scenario: Indexes

- **WHEN** querying candidates for a turn
- **THEN** the PK index on `(turn_id, place_id)` supports efficient lookup
- **WHEN** ordering by probability
- **THEN** an index on `(turn_id, probability DESC)` supports efficient ordering

#### Scenario: RLS policy

- **WHEN** a user queries `game_turn_candidates`
- **THEN** they can only see rows where the parent turn's session belongs to them
- **AND** policy joins through `game_turns` → `game_sessions`

### Requirement: Game Answers Table Removal

The system SHALL remove the `game_answers` table as its functionality is replaced by `game_turns`.

#### Scenario: Table removal

- **WHEN** the schema migration runs
- **THEN** `game_answers` table is dropped
- **AND** all references to `game_answers` in functions and views are updated to use `game_turns`

#### Scenario: Historical data

- **WHEN** the migration runs in development
- **THEN** existing `game_answers` data is NOT migrated (clean slate)
- **AND** any in-progress games are effectively reset

### Requirement: Game Sessions Cleanup

The system SHALL remove the `next_turn` JSONB column from `game_sessions`.

#### Scenario: Column removal

- **WHEN** the schema migration runs
- **THEN** `game_sessions.next_turn` column is dropped
- **AND** status is COMPUTED in `game_state` view based on `game_turns` and `was_correct`

## MODIFIED Requirements

### Requirement: Game State View

The system SHALL expose current game state via a view named `game_state` with typed columns.

#### Scenario: View rename

- **WHEN** the schema migration runs
- **THEN** `game_session_state` view is dropped and replaced with `game_state`

#### Scenario: Flat typed columns

- **WHEN** querying `game_state`
- **THEN** it returns typed columns:
  - `session_id` (uuid)
  - `description` (text)
  - `status` (game_session_status enum, computed)
  - `turn_number` (integer, nullable - current turn)
  - `action` (turn_action enum, nullable - from current game_turns row)
  - `question_text` (text, nullable)
  - `question_type` (question_type enum, nullable)
  - `trait_id` (uuid, nullable)
  - `geographic_region_id` (uuid, nullable)
  - `guess_place_id` (uuid, nullable)
  - `guess_place_name` (text, nullable)
  - `place_id` (uuid, nullable - final place when won/submitted)
  - `place_name` (text, nullable)
  - `place_lat` (double precision, nullable)
  - `place_lng` (double precision, nullable)
  - `total_turns` (integer - count of turns played)
- **AND** no JSONB columns are returned

#### Scenario: Status computation

- **WHEN** computing status in the view
- **THEN** status is derived as:
  - `'won'` if `was_correct = TRUE`
  - `'ended'` if `was_correct = FALSE` and `place_id IS NOT NULL`
  - `'needs_submission'` if no pending turn exists and `was_correct IS NULL`
  - `'active'` if a pending turn exists (answer IS NULL in game_turns)

#### Scenario: RLS inheritance

- **WHEN** querying the view
- **THEN** RLS from `game_sessions` is applied
- **AND** users only see their own sessions

### Requirement: Get Turn Candidates Function

The system SHALL provide a typed function for fetching candidates for a turn.

#### Scenario: Function signature

- **WHEN** calling `get_turn_candidates(p_turn_id uuid)`
- **THEN** it returns `TABLE(id uuid, name text, lat double precision, lng double precision, probability double precision, description_similarity double precision)`
- **AND** Supabase generates TypeScript types for the return columns

#### Scenario: Join with places

- **WHEN** fetching candidates
- **THEN** the function joins `game_turn_candidates` with `places` to include place details
- **AND** orders by probability DESC

#### Scenario: Security

- **WHEN** calling the function
- **THEN** it is SECURITY DEFINER with hardened search_path
- **AND** it validates that the turn's session belongs to the calling user

### Requirement: Get Session History Function

The system SHALL provide a typed function for fetching turn history.

#### Scenario: Function signature

- **WHEN** calling `get_session_history(p_session_id uuid)`
- **THEN** it returns all turns for the session with typed columns:
  - `turn_number`, `action`, `question_text`, `question_type`, `guess_place_name`, `answer`, `answered_at`
- **AND** orders by turn_number ASC

#### Scenario: Security

- **WHEN** calling the function
- **THEN** it validates that the session belongs to the calling user

### Requirement: Question Count

The system SHALL derive question count from `game_turns` instead of `game_answers`.

#### Scenario: Question count derivation

- **WHEN** counting questions in a session
- **THEN** count rows in `game_turns` where `action = 'question'` and `answer IS NOT NULL`
- **AND** this replaces the previous count from `game_answers`
