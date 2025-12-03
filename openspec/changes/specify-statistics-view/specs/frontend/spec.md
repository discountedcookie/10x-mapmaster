## MODIFIED Requirements

### Requirement: Stats and Settings UI

The system SHALL present stats views and user settings without embedding game logic.

#### Scenario: Stats views routing

- **WHEN** users navigate to /stats or /stats/global
- **THEN** the StatisticsView route renders and requests statistics from the corresponding database views.

#### Scenario: Stats view states

- **WHEN** the statistics view is used
- **THEN** it handles loading, error, empty (no games), and populated states explicitly.
