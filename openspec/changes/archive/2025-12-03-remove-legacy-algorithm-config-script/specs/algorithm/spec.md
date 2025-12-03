## ADDED Requirements

### Requirement: Algorithm Evaluation Tooling

The system SHALL document and use supported mechanisms for evaluating and testing algorithm behavior without relying on legacy ad-hoc scripts.

#### Scenario: Legacy scripts removed

- **WHEN** contributors look for algorithm evaluation tooling
- **THEN** they do not find legacy scripts like scripts/test-algorithm-configs.ts referenced as part of the supported workflow.

#### Scenario: Documented workflow

- **WHEN** evaluating or testing algorithm behavior
- **THEN** contributors follow the workflows and tooling described in the algorithm and operations specs instead of deprecated scripts.
