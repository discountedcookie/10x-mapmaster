## ADDED Requirements

### Requirement: Learning Trigger on Approval

The system SHALL trigger trait regeneration when a session is approved (pending_review becomes false).

#### Scenario: Approval firing

- **WHEN** game_sessions.pending_review transitions from TRUE to FALSE and place_id is set
- **THEN** regenerate_place_traits(place_id) is invoked

#### Scenario: No-op conditions

- **WHEN** place_id is NULL or pending_review does not change
- **THEN** the trigger does not call regeneration
