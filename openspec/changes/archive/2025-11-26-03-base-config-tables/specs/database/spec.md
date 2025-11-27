## ADDED Requirements

### Requirement: Configuration Tables

The system SHALL store configuration in separate public and private tables with appropriate access controls.

#### Scenario: Public config access

- **WHEN** authenticated users query public.config
- **THEN** they can read key/value pairs intended for clients

#### Scenario: Private config protection

- **WHEN** accessing game_logic.config
- **THEN** only SECURITY DEFINER functions or service_role can read/write; clients cannot access directly

#### Scenario: Config integrity

- **WHEN** inserting config rows
- **THEN** keys are unique and values are non-null JSON
