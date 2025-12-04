## MODIFIED Requirements

### Requirement: Gameplay UI

The system SHALL present gameplay UI elements driven by backend data without embedding game logic.

#### Scenario: Chat and input

- **WHEN** a turn is active
- **THEN** chat history of prior turns is visible and contextual input allows answering, guessing, or giving up per action

#### Scenario: Candidates and map hooks

- **WHEN** candidates are present
- **THEN** they are listed with confidence bars and can drive map panning/highlights

#### Scenario: Status indicators

- **WHEN** session status/turns change
- **THEN** badges reflect active/won/needs_submission/ended and turn counts

#### Scenario: State-based component architecture

- **WHEN** rendering game states
- **THEN** each game state (loading, error, active, won, needs_submission, ended) is rendered by a dedicated component via dynamic component pattern
- **AND** GameView acts as thin orchestrator for state composition only

## ADDED Requirements

### Requirement: Map Layer Encapsulation

The system SHALL encapsulate map layer management in composables, not views or state components.

#### Scenario: Candidates layer lifecycle

- **WHEN** candidates, hide-circles setting, or highlighted candidate changes
- **THEN** `useGameMap` automatically updates the candidates layer via `mapLayersStore`
- **AND** `GameView` does not call `mapLayersStore` directly
- **AND** `GameView` does not have `watch` blocks for layer registration

#### Scenario: Layer registration ownership

- **WHEN** `useGameMap` is initialized
- **THEN** it sets up internal watchers for candidates and highlight state
- **AND** it calls `registerCandidatesLayer` internally when data changes
- **AND** consumers only need to provide `hoveredCandidateId` ref if desired

### Requirement: Map Camera Encapsulation

The system SHALL encapsulate map camera behavior in composables, not state components.

#### Scenario: Fit bounds to candidates

- **WHEN** the game is active and candidates change
- **THEN** `useGameMap` (or a dedicated camera composable) handles fitting bounds to candidates
- **AND** `GameActive` does not call `camera.fitBounds` directly
- **AND** `GameActive` does not compute bounds from candidate coordinates

#### Scenario: State component purity

- **WHEN** rendering game state components (GameActive, GameWon, etc.)
- **THEN** they read data from stores/composables
- **AND** they emit user events (e.g., answer clicks)
- **AND** they MAY write to high-level refs exposed by composables (e.g., `hoveredCandidateId`)
- **AND** they do NOT call `mapLayersStore`, MapLibre instances, or camera methods directly
