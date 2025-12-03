## ADDED Requirements

### Requirement: submit_place Database Behavior

The system SHALL implement submit_place as a database function that enforces ownership, session state, and enrichment side effects.

#### Scenario: Inputs and outputs

- **WHEN** the submit_place function is called
- **THEN** it accepts a session identifier and an osm_id, and returns either a success payload or a standardized error_response.

#### Scenario: Side effects on success

- **WHEN** submit_place succeeds
- **THEN** a place row is created or updated, the session is linked to the place, pending_review and was_correct fields are set appropriately, and any learning triggers required by the database spec are invoked.

#### Scenario: No side effects on error

- **WHEN** submit_place returns an error_response
- **THEN** it does not create or update place rows and does not change existing session state.
