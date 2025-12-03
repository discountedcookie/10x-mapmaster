## ADDED Requirements

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
