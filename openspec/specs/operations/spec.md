# operations Specification

## Purpose

Defines operational concerns including rate limiting, maintenance jobs, and monitoring. These ensure the system remains performant and protected from abuse.
## Requirements
### Requirement: Rate Limiting

The system SHALL enforce per-user rate limits for RPC actions using database primitives.

#### Scenario: Limit enforcement

- **WHEN** check_rate_limit(user_id, action) is called
- **THEN** it counts requests within the configured window and raises an error when the limit is exceeded

#### Scenario: Logging

- **WHEN** a request is allowed
- **THEN** it is logged to rate_limit_log with user_id, action, and timestamp

#### Scenario: Configuration

- **WHEN** limits are not explicitly set
- **THEN** defaults for start_game, play_turn, and submit_place are applied from config

### Requirement: Maintenance Jobs

The system SHALL automate cleanup for rate limiting logs and abandoned sessions using pg_cron.

#### Scenario: Rate limit cleanup

- **WHEN** pg_cron runs the rate-limit cleanup job
- **THEN** entries older than the configured window are deleted from rate_limit_log

#### Scenario: Abandoned session cleanup

- **WHEN** pg_cron runs the session cleanup job
- **THEN** sessions considered abandoned are removed according to the defined criteria

#### Scenario: Scheduling and permissions

- **WHEN** jobs execute
- **THEN** they run under appropriate privileges and on the defined schedule

### Requirement: Deprecated Tooling Governance

The system SHALL remove deprecated operational tooling from the supported workflow and keep documentation aligned.

#### Scenario: Script removal

- **WHEN** a script like scripts/test-algorithm-configs.ts is no longer part of the supported workflow
- **THEN** it is removed from the repository and from any docs that previously referenced it.

#### Scenario: Clean operational docs

- **WHEN** reading operational documentation
- **THEN** only current, supported tools and scripts are referenced for algorithm evaluation and related tasks.

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

### Requirement: CI Pipeline

The system SHALL run automated quality checks on every PR and main build.

#### Scenario: Lint/type/unit

- **WHEN** CI runs
- **THEN** linting, type checking, and unit tests execute with caching

#### Scenario: Database tests

- **WHEN** CI runs
- **THEN** pgTAP database tests run via supabase test db

#### Scenario: Coverage

- **WHEN** tests complete
- **THEN** unit test coverage is uploaded/reported as configured

### Requirement: Security Scans

The system SHALL run automated security scans in CI for code, dependencies, and best practices.

#### Scenario: Code scanning

- **WHEN** CI runs
- **THEN** CodeQL executes for supported languages

#### Scenario: Static analysis and secrets

- **WHEN** CI runs
- **THEN** Semgrep security rules and Trufflehog secret scanning execute

#### Scenario: Best-practice scoring

- **WHEN** scheduled
- **THEN** OSSF Scorecard runs to report repository posture

