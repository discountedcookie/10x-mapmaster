## MODIFIED Requirements

### Requirement: Frontend Shell and Routing

The system SHALL provide a layout and routes for the application shell without embedding game logic.

#### Scenario: Layout

- **WHEN** the app loads
- **THEN** MapLayout renders a globe canvas (using MapLibre globe projection) with a floating panel container

#### Scenario: Routing

- **WHEN** navigating
- **THEN** routes /, /game/:id, /login, /signup, /stats, /stats/global are available with navigation controls

#### Scenario: Presentation-only shell

- **WHEN** rendering the shell
- **THEN** it remains presentation-only and defers all game logic to RPC calls

#### Scenario: Globe projection

- **WHEN** the map initializes
- **THEN** it uses globe projection (not flat 2D) with atmospheric styling
