## ADDED Requirements

### Requirement: Ops Tooling and Docs

The system SHALL document and script local setup, seeds, and type generation for developers.

#### Scenario: Environment setup

- **WHEN** developers follow README/.env.example
- **THEN** they can run Bun, Supabase, and Ollama with required variables configured

#### Scenario: Seeds and scripts

- **WHEN** seeding or regenerating data
- **THEN** scripts cover required tables and steps are documented

#### Scenario: Types generation

- **WHEN** generating Supabase types
- **THEN** a documented script produces current types for frontend use
