## ADDED Requirements

### Requirement: Unit Test Coverage and Stability

The system SHALL provide unit tests for core frontend behavior that remain aligned with the specified UI and store behavior.

#### Scenario: Gameplay UI tests

- **WHEN** running unit tests for the gameplay UI and related stores
- **THEN** tests reflect the specified behavior (e.g., correct store imports, expected labels/text, map integration points) and pass when the implementation conforms to the spec.

#### Scenario: i18n tests

- **WHEN** running i18n unit tests
- **THEN** expectations match the localized strings and locale codes defined by the frontend specification.

#### Scenario: Map integration tests

- **WHEN** running tests that depend on map components
- **THEN** they use stable mocks for map libraries so that tests verify frontend behavior without depending on external rendering details.
