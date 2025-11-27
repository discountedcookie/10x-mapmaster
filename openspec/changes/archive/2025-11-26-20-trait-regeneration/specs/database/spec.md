## ADDED Requirements

### Requirement: Trait Regeneration

The system SHALL regenerate a place's traits and embedding using enrichment data and approved session descriptions.

#### Scenario: Full regeneration

- **WHEN** regenerate_place_traits(place_id) runs
- **THEN** it combines place enrichment data and all approved session descriptions to extract traits, replaces place_traits, and regenerates the place embedding

#### Scenario: Robustness

- **WHEN** required data is missing or extraction fails
- **THEN** the function handles errors explicitly and avoids partial updates
