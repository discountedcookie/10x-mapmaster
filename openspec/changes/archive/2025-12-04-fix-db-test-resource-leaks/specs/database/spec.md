## ADDED Requirements

### Requirement: Database Test Resource Hygiene

The system SHALL structure database tests to avoid leaking TupleDesc or similar resources during pgTAP runs.

#### Scenario: Unused query results

- **WHEN** tests execute queries whose results are not inspected
- **THEN** they use PERFORM or equivalent patterns so that no TupleDesc resources are left open.

#### Scenario: Set-returning functions

- **WHEN** tests call set-returning functions
- **THEN** results are fully consumed or assigned in a way that prevents resource leaks.

#### Scenario: Clean test runs

- **WHEN** running the full pgTAP suite
- **THEN** no TupleDesc resource leak warnings are emitted as part of normal test execution.
