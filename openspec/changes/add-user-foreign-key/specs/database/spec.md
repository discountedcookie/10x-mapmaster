## ADDED Requirements

### Requirement: User Referential Integrity

The system SHALL enforce referential integrity between game_sessions and auth.users.

#### Scenario: User deletion cascades to sessions

- **WHEN** a user is deleted from auth.users
- **THEN** all their game_sessions are deleted
- **AND** no orphaned sessions remain

#### Scenario: Invalid user_id rejected

- **WHEN** attempting to create a game_session with non-existent user_id
- **THEN** the insert fails with a foreign key violation
