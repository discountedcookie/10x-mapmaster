# edge-functions Specification

## Purpose
TBD - created by archiving change 24-generate-embedding-fn. Update Purpose after archive.
## Requirements
### Requirement: generate-embedding Edge Function

The system SHALL provide an edge function to generate 384d embeddings from text using configurable providers.

#### Scenario: Successful embedding

- **WHEN** called with valid text
- **THEN** it returns a 384d embedding and does not expose secrets

#### Scenario: Provider configuration

- **WHEN** selecting providers
- **THEN** configuration/env control the provider used without code changes

#### Scenario: Error handling

- **WHEN** provider or input errors occur
- **THEN** standardized errors are returned and no sensitive data is leaked

### Requirement: call-llm Edge Function

The system SHALL provide an edge function to call LLMs for text generation with configurable providers.

#### Scenario: Successful LLM call

- **WHEN** called with valid parameters (model, temperature, max_tokens, prompt)
- **THEN** it returns generated text and hides provider secrets

#### Scenario: Error handling

- **WHEN** provider or input errors occur
- **THEN** standardized errors are returned with no sensitive data leaked

#### Scenario: Configuration

- **WHEN** changing providers
- **THEN** configuration/env selects providers without code changes

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

### Requirement: search-place Edge Function

The system SHALL provide an edge function for place search to support frontend autocomplete.

#### Scenario: Successful search

- **WHEN** called with a valid query
- **THEN** it returns normalized suggestions (name, osm_id, lat/lng) suitable for selection

#### Scenario: Error handling

- **WHEN** provider errors or invalid input occur
- **THEN** standardized errors are returned without exposing secrets

