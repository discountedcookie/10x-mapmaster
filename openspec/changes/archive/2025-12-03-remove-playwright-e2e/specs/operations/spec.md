## ADDED Requirements

### Requirement: CI Pipeline Test Coverage

The CI pipeline SHALL execute unit tests and database tests on every push and pull request.

#### Scenario: Unit tests execute in CI

- **WHEN** a push or pull request is created
- **THEN** vitest unit tests run with coverage reporting

#### Scenario: Database tests execute in CI

- **WHEN** a push or pull request is created
- **THEN** pgTAP database tests run against a Supabase instance

### Requirement: CI Pipeline Does Not Include E2E

The CI pipeline SHALL NOT include Playwright E2E tests.

#### Scenario: No E2E job in workflow

- **WHEN** the CI workflow is triggered
- **THEN** no Playwright browser tests are executed
- **AND** no Playwright dependencies are installed


