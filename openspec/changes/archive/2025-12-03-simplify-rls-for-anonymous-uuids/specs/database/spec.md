## MODIFIED Requirements

### Requirement: Auth Model and Security Posture

The system SHALL define and enforce an auth model covering anonymous, registered, and service roles, and prescribe SECURITY DEFINER and RLS guardrails.

#### Scenario: Auth personas

- **WHEN** the database evaluates access
- **THEN** it recognizes anonymous users and registered users as having non-null UUID auth.uid() values, and service_role with elevated privileges.

#### Scenario: RLS posture

- **WHEN** applying RLS
- **THEN** user-owned tables restrict by auth.uid(); public data is read-open; private tables are blocked except to service_role, without relying on user_id IS NULL branches.

### Requirement: Session and Answer RLS

The system SHALL enforce row-level security for game_sessions and game_answers based on ownership.

#### Scenario: UUID-based ownership

- **WHEN** any user (anonymous or registered) accesses sessions/answers
- **THEN** they can only see and modify rows where game_sessions.user_id = auth.uid().

#### Scenario: Service role access

- **WHEN** service_role accesses sessions/answers
- **THEN** it can manage all rows for maintenance and internal operations.
