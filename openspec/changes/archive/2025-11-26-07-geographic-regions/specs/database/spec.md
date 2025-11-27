## ADDED Requirements

### Requirement: Geographic Regions

The system SHALL store geographic regions with geometry and level metadata for spatial filtering.

#### Scenario: Region fields

- **WHEN** a region is stored
- **THEN** it has id, name, level, geometry, and timestamps

#### Scenario: Constraints and indexes

- **WHEN** validating regions
- **THEN** level is constrained to allowed values; GIST index exists on geometry

#### Scenario: Access

- **WHEN** reading regions
- **THEN** data is publicly readable; writes restricted to authorized roles
