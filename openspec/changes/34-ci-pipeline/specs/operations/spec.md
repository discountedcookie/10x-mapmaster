## ADDED Requirements

### Requirement: CI Pipeline

The system SHALL run automated quality checks on every PR and main build.

#### Scenario: Lint/type/unit

- **WHEN** CI runs
- **THEN** linting, type checking, and unit tests execute with caching

#### Scenario: Database tests

- **WHEN** CI runs
- **THEN** pgTAP database tests run via supabase test db

#### Scenario: E2E tests

- **WHEN** CI runs
- **THEN** Playwright E2E with mocked embeddings executes headless

#### Scenario: Coverage

- **WHEN** tests complete
- **THEN** coverage is uploaded/reported as configured
