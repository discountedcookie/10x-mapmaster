## ADDED Requirements

### Requirement: Store Mutation Pattern

The system SHALL mutate Pinia store state only through defined actions.

#### Scenario: Adding a place via realtime

- **WHEN** a realtime INSERT event is received
- **THEN** the `addPlace` action is called
- **AND** Vue devtools records the action

#### Scenario: Updating a place via realtime

- **WHEN** a realtime UPDATE event is received
- **THEN** the `updatePlace` action is called
- **AND** Vue devtools records the action

#### Scenario: Removing a place via realtime

- **WHEN** a realtime DELETE event is received
- **THEN** the `removePlace` action is called
- **AND** Vue devtools records the action

### Requirement: Cross-Store Dependencies

The system SHALL inject cross-store dependencies at store setup time, not inside computeds.

#### Scenario: Store accessing another store

- **WHEN** a store needs data from another store
- **THEN** the dependency is established at setup time
- **AND** computeds reference the injected store instance
