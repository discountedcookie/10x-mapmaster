## ADDED Requirements

### Requirement: Statistics Capability

The system SHALL expose statistics about user performance as a read-only capability built on stored game session data.

#### Scenario: User statistics

- **WHEN** requesting user statistics
- **THEN** the system returns aggregated metrics for the calling user derived from game_sessions and related tables.

#### Scenario: Global statistics

- **WHEN** requesting global statistics
- **THEN** the system returns aggregated metrics across all users, consistent with the database stats views.
