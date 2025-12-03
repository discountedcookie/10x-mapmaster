## ADDED Requirements

### Requirement: Frontend Test Suite Structure

The system SHALL structure frontend unit tests into manageable, focused files that respect project size guidelines while preserving behavior.

#### Scenario: Split game store tests

- **WHEN** organizing tests for the game session store
- **THEN** tests are grouped into smaller files by concern (e.g., initial state, actions, derived state) rather than a single oversized file.

#### Scenario: Split places store tests

- **WHEN** organizing tests for the places store
- **THEN** tests are grouped into smaller suites that cover core behavior, fetching, search, and reset behavior.

#### Scenario: Split statistics composable tests

- **WHEN** organizing tests for the statistics composable
- **THEN** tests are grouped to separately cover initial state, fetch logic, and reactivity behavior.
