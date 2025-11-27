## ADDED Requirements

### Requirement: Traits and Place-Trait Association

The system SHALL store canonical traits and link them to places via a join table.

#### Scenario: Trait definition

- **WHEN** a trait is stored
- **THEN** it has id, clause, optional embedding_id, and timestamps

#### Scenario: Place-trait relationship

- **WHEN** linking places to traits
- **THEN** a join table with PK(place_id, trait_id) and FKs to places/traits is used with appropriate indexes

#### Scenario: Access

- **WHEN** reading traits and associations
- **THEN** they are readable by all; writes are restricted to authorized roles
