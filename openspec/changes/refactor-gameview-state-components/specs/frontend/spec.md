## MODIFIED Requirements

### Requirement: Gameplay UI

The system SHALL present gameplay UI elements driven by backend next_turn data without embedding game logic.

#### Scenario: Chat and input

- **WHEN** a turn is active
- **THEN** chat history of prior turns is visible and contextual input allows answering, guessing, or giving up per next_turn action

#### Scenario: Candidates and map hooks

- **WHEN** candidates are present
- **THEN** they are listed with confidence bars and can drive map panning/highlights

#### Scenario: Status indicators

- **WHEN** session status/turns change
- **THEN** badges reflect active/won/needs_submission/ended and turn counts

#### Scenario: State-based component architecture

- **WHEN** rendering game states
- **THEN** each game state (loading, error, active, won, needs_submission, ended) is rendered by a dedicated component via dynamic component pattern
- **AND** each state component handles its own map controls (camera, 3D layers)
- **AND** GameView acts as thin orchestrator managing only candidates layer and state composition
