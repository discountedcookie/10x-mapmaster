## MODIFIED Requirements

### Requirement: play_turn RPC

The system SHALL expose play_turn that records answers, creates the next turn, and returns the new state.

#### Scenario: Successful turn

- **WHEN** called with a valid session_id and answer
- **THEN** the current turn's `answer` and `answered_at` are set in `game_turns`
- **AND** if the game continues, a new `game_turns` row is inserted with new candidates in `game_turn_candidates`
- **AND** the function returns the updated game state as typed columns matching `game_state`

#### Scenario: Return type

- **WHEN** play_turn completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_state`
- **AND** Supabase generates TypeScript types for all return columns
- **AND** no JSONB is returned

#### Scenario: Validation and errors

- **WHEN** input is invalid, session not found/owned, or rate limits exceeded
- **THEN** the function raises an exception and leaves state unchanged

### Requirement: start_game RPC

The system SHALL expose start_game that returns the initial game state.

#### Scenario: Successful start

- **WHEN** called with valid description and language_code
- **THEN** a session is created in `game_sessions`
- **AND** the first turn is inserted into `game_turns` with `turn_number = 1` and `answer = NULL`
- **AND** initial candidates are inserted into `game_turn_candidates` for that turn
- **AND** the function returns the initial game state as typed columns

#### Scenario: Return type

- **WHEN** start_game completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_state`
- **AND** no JSONB is returned

### Requirement: submit_place RPC

The system SHALL expose submit_place that handles place submission and returns the updated state.

#### Scenario: Successful submission

- **WHEN** called with valid session_id and osm_id
- **THEN** enrichment runs and place is created/updated
- **AND** session is linked to place
- **AND** no new turn is created (game is over)
- **AND** the function returns the updated game state as typed columns

#### Scenario: Return type

- **WHEN** submit_place completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_state`
- **AND** no JSONB is returned

### Requirement: Internal Game Logic

The system SHALL update internal game logic functions to use the new tables.

#### Scenario: get_candidates

- **WHEN** `get_candidates` is called for an existing session
- **THEN** it queries `game_turn_candidates` for the current turn joined with `places`
- **AND** returns properly typed rows (not JSONB)

#### Scenario: decide_next_turn

- **WHEN** `decide_next_turn` determines the next action
- **THEN** it inserts a new row into `game_turns` with `answer = NULL`
- **AND** it inserts candidates into `game_turn_candidates` for that turn
- **AND** on game end (no candidates, max turns): it does NOT insert a new turn

#### Scenario: handle_question

- **WHEN** handling a question answer
- **THEN** the function updates the current `game_turns` row (sets `answer`, `answered_at`)
- **AND** computes new candidate scores
- **AND** calls `decide_next_turn` which creates the next turn row + candidates

#### Scenario: handle_guess

- **WHEN** handling a correct guess
- **THEN** the function updates the current `game_turns` row (sets `answer = 'yes'`, `answered_at`)
- **AND** sets `game_sessions.was_correct = TRUE` and `place_id`
- **WHEN** handling a wrong guess
- **THEN** the function updates the current `game_turns` row (sets `answer = 'no'`, `answered_at`)
- **AND** calls `decide_next_turn` with the eliminated place excluded

#### Scenario: Algorithm functions

- **WHEN** `filter_candidates_for_geography` processes geographic answers
- **THEN** it returns filtered candidates (not table mutation) for insertion into next turn
- **WHEN** `adjust_candidates_for_answer` processes semantic answers
- **THEN** it returns adjusted candidates (not table mutation) for insertion into next turn
- **WHEN** `apply_softmax_to_candidates` recalculates probabilities
- **THEN** it returns candidates with updated probabilities for insertion into next turn

### Requirement: Record Game Answer Removal

The system SHALL remove `record_game_answer` function as turn recording is now part of the turn table.

#### Scenario: Function removal

- **WHEN** the migration runs
- **THEN** `record_game_answer` function is dropped
- **AND** turn recording is handled by UPDATE on `game_turns` instead

### Requirement: JSONB Builder Removal

The system SHALL remove JSONB builder functions.

#### Scenario: Function removal

- **WHEN** the migration runs
- **THEN** `build_guess_turn` function is dropped
- **AND** `build_question_turn` function is dropped
- **AND** turn data is inserted directly into `game_turns` table
