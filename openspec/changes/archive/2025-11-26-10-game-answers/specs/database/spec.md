## ADDED Requirements

### Requirement: Game Answers Table

The system SHALL store answers with exactly one of trait_id, geographic_region_id, or place_id populated.

#### Scenario: One-of enforcement

- **WHEN** an answer is stored
- **THEN** exactly one of trait_id, geographic_region_id, or place_id is non-null via CHECK

#### Scenario: Relationships and cleanup

- **WHEN** sessions or referenced entities are deleted
- **THEN** FKs cascade appropriately to keep answers consistent

#### Scenario: Query performance

- **WHEN** querying answers
- **THEN** indexes exist on session_id and a supporting index for polymorphic lookups
