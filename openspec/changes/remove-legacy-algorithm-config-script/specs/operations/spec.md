## ADDED Requirements

### Requirement: Deprecated Tooling Governance

The system SHALL remove deprecated operational tooling from the supported workflow and keep documentation aligned.

#### Scenario: Script removal

- **WHEN** a script like scripts/test-algorithm-configs.ts is no longer part of the supported workflow
- **THEN** it is removed from the repository and from any docs that previously referenced it.

#### Scenario: Clean operational docs

- **WHEN** reading operational documentation
- **THEN** only current, supported tools and scripts are referenced for algorithm evaluation and related tasks.
