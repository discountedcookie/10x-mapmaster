## ADDED Requirements

### Requirement: Win State Camera Animation

The system SHALL animate the camera around the winning place when a game is won.

#### Scenario: Win orbit

- **WHEN** game status changes to 'won'
- **THEN** camera gently orbits around the winning place with success glow on marker

#### Scenario: Zoom framing

- **WHEN** entering win state
- **THEN** camera zooms to show place polygon at appropriate level

#### Scenario: Give-up state

- **WHEN** game ends via give-up
- **THEN** camera frames the correct place without celebratory animation
