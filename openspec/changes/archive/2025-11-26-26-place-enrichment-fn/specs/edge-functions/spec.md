## ADDED Requirements

### Requirement: place-enrichment Edge Function

The system SHALL provide an edge function to fetch place data and extract traits for submissions.

#### Scenario: Successful enrichment

- **WHEN** called with a valid osm_id
- **THEN** it returns normalized Nominatim data and an extracted trait list in structured form

#### Scenario: Error handling

- **WHEN** Nominatim or extraction fails
- **THEN** standardized errors are returned without leaking secrets

#### Scenario: Security

- **WHEN** responding
- **THEN** only necessary place/trait data is returned; no secrets are exposed
