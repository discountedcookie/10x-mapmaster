## MODIFIED Requirements

### Requirement: Place Deduplication

The system SHALL merge duplicate places based on matching `osm_id` or spatial/name similarity.

When merging duplicates:

- The place with highest `times_encountered` is kept
- `times_encountered` values are summed
- `game_sessions` referencing deleted places are updated to the kept place
- Place traits remain linked to their original places (no trait merging)

#### Scenario: Exact OSM ID duplicates

- **WHEN** two places have the same `osm_id`
- **THEN** they are merged into one place
- **AND** `times_encountered` is the sum of both
- **AND** the place with more encounters is kept

#### Scenario: Spatial and name similarity duplicates

- **WHEN** two places are within 100 meters of each other
- **AND** their names have similarity > 0.8
- **THEN** they are merged into one place
- **AND** `times_encountered` is the sum of both

#### Scenario: Game session references updated

- **WHEN** a duplicate place is deleted
- **AND** it was referenced by game_sessions
- **THEN** those sessions are updated to reference the kept place
