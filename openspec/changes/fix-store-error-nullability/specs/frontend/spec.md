## ADDED Requirements

### Requirement: Store Error Nullability Convention

The system SHALL use a consistent nullability convention for error state in frontend stores and composables.

#### Scenario: Error state type

- **WHEN** defining error refs in stores or composables
- **THEN** they use null as the "no error" value (e.g., Ref<string | null>) rather than undefined.

#### Scenario: Error reset behavior

- **WHEN** a previously errored operation later succeeds
- **THEN** the corresponding error state is reset to null.

#### Scenario: Test expectations

- **WHEN** running unit tests for stores and composables with error state
- **THEN** tests expect null for empty error state and match the standardized nullability convention.
