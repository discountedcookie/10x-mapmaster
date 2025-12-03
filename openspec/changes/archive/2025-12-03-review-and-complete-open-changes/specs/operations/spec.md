## ADDED Requirements

### Requirement: OpenSpec Change Governance

The system SHALL define a process for reviewing, completing, and archiving OpenSpec changes.

#### Scenario: Active change inventory

- **WHEN** reviewing active OpenSpec changes
- **THEN** each change has a recorded status including tasks completed, domains affected, and a brief summary of intent.

#### Scenario: Disposition of changes

- **WHEN** deciding how to handle active changes
- **THEN** each change is classified as to be completed now, split into follow-up changes, or archived with a rationale.

#### Scenario: Archiving process

- **WHEN** archiving a change
- **THEN** it is moved under openspec/changes/archive/ with a short status note, and openspec/project.md documents the criteria and process used.
