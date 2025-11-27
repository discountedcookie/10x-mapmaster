## ADDED Requirements

### Requirement: Session and Answer RLS

The system SHALL enforce row-level security for game_sessions and game_answers based on ownership.

#### Scenario: Registered ownership

- **WHEN** a registered user accesses sessions/answers
- **THEN** they can only see and modify rows where game_sessions.user_id = auth.uid()

#### Scenario: Anonymous ownership

- **WHEN** an anonymous user (auth.uid() IS NULL) accesses
- **THEN** they can only see/modify rows whose user_id IS NULL

#### Scenario: Service role

- **WHEN** service_role accesses
- **THEN** it can manage all rows for maintenance and internal operations
