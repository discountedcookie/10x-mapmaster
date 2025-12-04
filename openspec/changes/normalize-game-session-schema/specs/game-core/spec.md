## MODIFIED Requirements

### Requirement: play_turn RPC

The system SHALL expose play_turn that records answers, updates game state, and returns the new state.

#### Scenario: Successful turn

- **WHEN** called with a valid session_id and answer
- **THEN** the answer is recorded in `game_answers`
- **AND** `game_session_candidates` are updated (scores adjusted or rows deleted)
- **AND** `game_turn` is updated with next action (or deleted if game ends)
- **AND** the function returns the updated game state as typed columns matching `game_session_state`

#### Scenario: Return type

- **WHEN** play_turn completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_session_state`
- **AND** Supabase generates TypeScript types for all return columns
- **AND** no JSONB is returned

#### Scenario: Validation and errors

- **WHEN** input is invalid, session not found/owned, or rate limits exceeded
- **THEN** the function raises an exception and leaves state unchanged

### Requirement: start_game RPC

The system SHALL expose start_game that returns the initial game state.

#### Scenario: Successful start

- **WHEN** called with valid description and language_code
- **THEN** a session is created
- **AND** initial candidates are inserted into `game_session_candidates`
- **AND** first turn is inserted into `game_turn`
- **AND** the function returns the initial game state as typed columns

#### Scenario: Return type

- **WHEN** start_game completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_session_state`
- **AND** no JSONB is returned

### Requirement: submit_place RPC

The system SHALL expose submit_place that handles place submission and returns the updated state.

#### Scenario: Successful submission

- **WHEN** called with valid session_id and osm_id
- **THEN** enrichment runs and place is created/updated
- **AND** session is linked to place
- **AND** `game_turn` row is deleted (game over)
- **AND** the function returns the updated game state as typed columns

#### Scenario: Return type

- **WHEN** submit_place completes successfully
- **THEN** it returns `TABLE(...)` with the same columns as `game_session_state`
- **AND** no JSONB is returned

### Requirement: Internal Game Logic

The system SHALL update internal game logic functions to use the new tables.

#### Scenario: get_candidates

- **WHEN** `get_candidates` is called
- **THEN** it queries `game_session_candidates` joined with `places`
- **AND** returns properly typed rows (not JSONB)

#### Scenario: decide_next_turn

- **WHEN** `decide_next_turn` determines the next action
- **THEN** it inserts or updates `game_turn` table with typed columns
- **AND** it does NOT update candidates (that happens in answer handlers)

#### Scenario: handle_question

- **WHEN** handling a question answer
- **THEN** the function reads current turn from `game_turn`
- **AND** updates `game_session_candidates` rows directly (UPDATE/DELETE statements)
- **AND** updates `game_turn` with next action via `decide_next_turn`

#### Scenario: handle_guess

- **WHEN** handling a guess answer
- **THEN** the function reads current turn from `game_turn`
- **AND** on correct guess: deletes `game_turn` row, sets session.was_correct
- **AND** on wrong guess: deletes candidate row from `game_session_candidates`, calls `decide_next_turn`

#### Scenario: Algorithm functions

- **WHEN** `filter_candidates_for_geography` processes geographic answers
- **THEN** it operates on `game_session_candidates` table directly (DELETE rows outside region)
- **WHEN** `adjust_candidates_for_answer` processes semantic answers
- **THEN** it operates on `game_session_candidates` table directly (UPDATE probability/scores)
- **WHEN** `apply_softmax_to_candidates` recalculates probabilities
- **THEN** it operates on `game_session_candidates` table directly (UPDATE probability)
