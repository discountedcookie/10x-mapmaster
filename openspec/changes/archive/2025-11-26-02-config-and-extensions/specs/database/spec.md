## ADDED Requirements

### Requirement: Schemas and Extensions

The system SHALL define required schemas and install core extensions and types for the database.

#### Scenario: Schemas and search_path

- **WHEN** deploying the database
- **THEN** schemas extensions, public, and game_logic exist and functions set search_path explicitly

#### Scenario: Extensions installed

- **WHEN** extensions are provisioned
- **THEN** pgvector (384d), PostGIS, and pg_cron are installed in the extensions schema and available

#### Scenario: Types and enums

- **WHEN** shared types are needed
- **THEN** enums (e.g., status, answer_value) and any composite types are defined centrally
