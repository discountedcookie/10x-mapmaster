## ADDED Requirements

### Requirement: Frontend Shell and Routing

The system SHALL provide a layout and routes for the application shell without embedding game logic.

#### Scenario: Layout

- **WHEN** the app loads
- **THEN** MapLayout renders a globe canvas with a floating panel container

#### Scenario: Routing

- **WHEN** navigating
- **THEN** routes /, /game/:id, /login, /signup, /stats, /stats/global are available with navigation controls

#### Scenario: Presentation-only shell

- **WHEN** rendering the shell
- **THEN** it remains presentation-only and defers all game logic to RPC calls
