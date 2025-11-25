# Operations Specification

## Purpose

Define deployment, testing, CI/CD, monitoring, and operational procedures for the geographic guessing game.

---

## Requirements

### Requirement: Development Environment

The system SHALL support local development with full functionality.

#### Scenario: Local services

- **WHEN** developing locally
- **THEN** use local Supabase instance
- **AND** Ollama for embeddings and LLM
- **AND** hot reload enabled

#### Scenario: Database reset

- **WHEN** schema changes needed
- **THEN** run `bun run db:rebuild` for clean reset

---

### Requirement: Production Environment

The system SHALL deploy to production with appropriate services.

#### Scenario: Production services

- **WHEN** running in production
- **THEN** use Supabase hosted cluster
- **AND** Supabase gte-small for embeddings
- **AND** configured LLM provider

#### Scenario: Frontend hosting

- **WHEN** deploying frontend
- **THEN** use GitHub Pages for static hosting

#### Scenario: Single environment

- **WHEN** deploying
- **THEN** same Supabase project for CI tests and production (no staging)

---

### Requirement: Database Migrations

The system SHALL use appropriate migration strategy per environment.

#### Scenario: Development migrations

- **WHEN** in development
- **THEN** single clean migration with database reset
- **AND** no migration history preserved

#### Scenario: Production migrations

- **WHEN** in production
- **THEN** incremental timestamped migrations
- **AND** rollback capability maintained

---

### Requirement: CI/CD Pipeline

The system SHALL automate testing and deployment.

#### Scenario: Automated checks

- **WHEN** code pushed or PR created
- **THEN** run lint (oxlint + ESLint)
- **AND** run type-check (vue-tsc)
- **AND** run database tests (pgTAP)
- **AND** run unit tests (Vitest)
- **AND** run E2E tests (Playwright)

#### Scenario: Deployment trigger

- **WHEN** tests pass on main branch
- **THEN** automatically deploy to GitHub Pages

---

### Requirement: Testing Strategy

The system SHALL test critical paths across all layers.

#### Scenario: Database tests (pgTAP)

- **WHEN** testing database
- **THEN** test core game logic functions
- **AND** test RLS policies and user isolation
- **AND** test input validation

#### Scenario: Unit tests (Vitest)

- **WHEN** testing frontend
- **THEN** test composables with business logic
- **AND** test store actions and getters
- **AND** test utility functions

#### Scenario: E2E tests (Playwright)

- **WHEN** testing flows
- **THEN** test: start → answer → win
- **AND** test: start → give up → submit
- **AND** test: anonymous → register → history preserved
- **AND** use mocked embeddings

---

### Requirement: Code Quality

The system SHALL enforce code quality standards.

#### Scenario: Dual-layer linting

- **WHEN** linting code
- **THEN** oxlint for fast feedback during development
- **AND** ESLint for comprehensive coverage in CI

#### Scenario: File size limit

- **WHEN** writing code
- **THEN** max 200 lines per file enforced

#### Scenario: Formatting

- **WHEN** formatting code
- **THEN** Prettier for TypeScript, Vue, JSON
- **AND** SQL formatting with uppercase keywords

---

### Requirement: Security Scanning

The system SHALL perform automated security checks.

#### Scenario: Security tools

- **WHEN** security checked
- **THEN** run CodeQL for code scanning
- **AND** run npm audit for dependencies
- **AND** run Semgrep for security patterns
- **AND** run Trufflehog for secret detection
- **AND** run OSSF Scorecard weekly

---

### Requirement: Rate Limiting

The system SHALL enforce rate limits to prevent abuse.

#### Scenario: Rate limits

- **WHEN** user makes requests
- **THEN** start_game: 10 per minute
- **AND** play_turn: 60 per minute
- **AND** submit_place: 10 per minute

#### Scenario: Rate limit enforcement

- **WHEN** limit exceeded
- **THEN** return error code rate_limit_exceeded (429)

---

### Requirement: Admin Workflows

The system SHALL support admin operations via Supabase Studio.

#### Scenario: Review pending sessions

- **WHEN** admin reviews session
- **THEN** approve (set pending_review=false, triggers learning)
- **OR** reject (delete session)

#### Scenario: Configuration changes

- **WHEN** admin changes config
- **THEN** takes effect on next RPC call
- **AND** no restart required

---

### Requirement: Logging and Monitoring

The system SHALL provide appropriate logging without sensitive data.

#### Scenario: Database logging

- **WHEN** database operations occur
- **THEN** PostgreSQL logs managed by Supabase

#### Scenario: Edge function logging

- **WHEN** edge functions execute
- **THEN** console.log/error visible in Supabase dashboard

#### Scenario: Frontend logging

- **WHEN** frontend errors occur
- **THEN** logged via consola
- **AND** reported to Sentry

#### Scenario: No sensitive logging

- **WHEN** logging
- **THEN** never log user descriptions or personal data
- **AND** never log sensitive configuration

---

### Requirement: Automated Maintenance

The system SHALL perform automated cleanup tasks.

#### Scenario: Abandoned session cleanup

- **WHEN** daily cron runs
- **THEN** delete active sessions with no activity for 24 hours

#### Scenario: Rate limit cleanup

- **WHEN** pg_cron runs
- **THEN** delete rate_limit_log entries older than window

---

### Requirement: Dependency Management

The system SHALL manage dependencies automatically.

#### Scenario: Dependabot updates

- **WHEN** dependencies outdated
- **THEN** Dependabot creates PRs weekly (Mondays)
- **AND** groups minor/patch updates
- **AND** separates major updates

---

### Requirement: Git Workflow

The system SHALL follow defined git conventions.

#### Scenario: Branch strategy

- **WHEN** making changes
- **THEN** use feature branches
- **AND** no direct commits to main

#### Scenario: Commit conventions

- **WHEN** committing
- **THEN** use scoped prefixes: feat:, fix:, chore:, docs:

#### Scenario: Pull requests

- **WHEN** merging to main
- **THEN** PR required
- **AND** must pass CI
