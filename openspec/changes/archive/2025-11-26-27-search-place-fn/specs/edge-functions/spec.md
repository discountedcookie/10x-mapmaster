## ADDED Requirements

### Requirement: search-place Edge Function

The system SHALL provide an edge function for place search to support frontend autocomplete.

#### Scenario: Successful search

- **WHEN** called with a valid query
- **THEN** it returns normalized suggestions (name, osm_id, lat/lng) suitable for selection

#### Scenario: Error handling

- **WHEN** provider errors or invalid input occur
- **THEN** standardized errors are returned without exposing secrets
