## ADDED Requirements

### Requirement: Frontend Deployment

The system SHALL deploy the frontend automatically to GitHub Pages after tests pass.

#### Scenario: Build and deploy

- **WHEN** changes land on the deploy branch (e.g., main)
- **THEN** the frontend is built, artifacts are published, and the site is updated on Pages

#### Scenario: Test gating

- **WHEN** deployment runs
- **THEN** it depends on successful lint/type/unit, database, and E2E jobs

#### Scenario: Configured environment

- **WHEN** building
- **THEN** required environment variables are provided securely
