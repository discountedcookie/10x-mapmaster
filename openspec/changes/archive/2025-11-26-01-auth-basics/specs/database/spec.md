## ADDED Requirements

### Requirement: Auth Model and Security Posture

The system SHALL define and enforce an auth model covering anonymous, registered, and service roles, and prescribe SECURITY DEFINER and RLS guardrails.

#### Scenario: Auth personas

- **WHEN** the database evaluates access
- **THEN** it recognizes anonymous users (auth.uid() is NULL), registered users (auth.uid() set), and service_role with elevated privileges

#### Scenario: SECURITY DEFINER guardrails

- **WHEN** a SECURITY DEFINER function requires user context
- **THEN** it checks auth.uid() IS NOT NULL and sets an explicit search_path

#### Scenario: RLS posture

- **WHEN** applying RLS
- **THEN** user-owned tables restrict by auth.uid(); public data is read-open; private tables are blocked except to service_role
