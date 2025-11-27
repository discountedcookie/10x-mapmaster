## ADDED Requirements

### Requirement: Stats and Settings UI

The system SHALL present stats views and user settings without embedding game logic.

#### Scenario: Stats views

- **WHEN** users open stats
- **THEN** user_stats/global_stats are displayed using data from database views

#### Scenario: Theme and language

- **WHEN** toggling theme or language
- **THEN** the UI updates accordingly and preferences are respected

#### Scenario: Accessibility

- **WHEN** interacting with settings and stats
- **THEN** controls are accessible (keyboard/ARIA/reduced motion)
