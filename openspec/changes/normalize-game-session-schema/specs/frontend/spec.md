## MODIFIED Requirements

### Requirement: Game Session Store

The system SHALL use Supabase-generated types for game session state.

#### Scenario: Store state type

- **WHEN** defining the game session store state
- **THEN** it uses the Supabase-generated type for the `game_session_state` view columns
- **AND** no manual type definitions are needed for session fields
- **AND** no `as unknown as` casts are used

#### Scenario: Candidates state

- **WHEN** the store holds candidates
- **THEN** candidates are stored in a separate ref (e.g., `candidates: Ref<Candidate[]>`)
- **AND** the type is the Supabase-generated return type for `get_session_candidates`
- **AND** candidates are fetched via the typed RPC function after each turn

#### Scenario: play_turn response

- **WHEN** `play_turn` completes
- **THEN** the store updates session state from the typed return value
- **AND** the store then fetches updated candidates via `get_session_candidates`
- **AND** both operations happen in sequence (turn → candidates)

#### Scenario: Initial load / refresh

- **WHEN** loading a game session (page refresh, navigation)
- **THEN** session state is fetched from `game_session_state` view
- **AND** candidates are fetched via `get_session_candidates`
- **AND** both are stored in their respective refs

### Requirement: Gameplay UI Components

The system SHALL consume typed session data without casts.

#### Scenario: Question display

- **WHEN** displaying a question in `GameActive`
- **THEN** the component reads `session.question_text` as a typed string
- **AND** no manual JSON parsing or casting is performed

#### Scenario: Guess display

- **WHEN** displaying a guess in `GameActive`
- **THEN** the component reads `session.guess_place_name` as a typed string
- **AND** no manual JSON parsing or casting is performed

#### Scenario: Candidates display

- **WHEN** displaying candidates on the map
- **THEN** `useGameMap` reads candidates as a typed array
- **AND** each candidate has typed `id`, `name`, `lat`, `lng`, `probability` fields
- **AND** no `as unknown as` casts are used

### Requirement: API Layer

The system SHALL use typed RPC calls.

#### Scenario: playTurn API

- **WHEN** `gameApi.playTurn` is called
- **THEN** it returns a typed object matching `game_session_state` columns
- **AND** the TypeScript type is auto-generated from Supabase

#### Scenario: getSessionCandidates API

- **WHEN** `gameApi.getSessionCandidates` is called
- **THEN** it calls the `get_session_candidates` RPC
- **AND** returns a typed array of candidates
- **AND** the TypeScript type is auto-generated from Supabase
