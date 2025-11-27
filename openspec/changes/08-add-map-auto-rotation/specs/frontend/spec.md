## ADDED Requirements

### Requirement: Map Auto-Rotation

The system SHALL auto-rotate the globe on the home page when idle.

#### Scenario: Idle rotation

- **WHEN** on home page with no active game
- **THEN** the globe slowly auto-rotates showing full globe view

#### Scenario: Interaction pause

- **WHEN** user interacts with the map (pan/zoom)
- **THEN** rotation pauses and resumes after idle timeout

#### Scenario: Game transition

- **WHEN** a game starts
- **THEN** rotation stops and camera transitions to game view
