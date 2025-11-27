## ADDED Requirements

### Requirement: Places Storage with Geometry

The system SHALL store places with geometry, embeddings, and review status for gameplay and visualization.

#### Scenario: Place fields

- **WHEN** a place is stored
- **THEN** it has id, name, osm_id (unique), lat, lng, geom, embedding_id, pending_review, timestamps

#### Scenario: Indexing and constraints

- **WHEN** querying places
- **THEN** GIST index exists on geom; unique constraint on osm_id; indexes on embedding_id/name as appropriate

#### Scenario: Access

- **WHEN** reading places
- **THEN** data is readable publicly; writes are restricted to authorized roles
