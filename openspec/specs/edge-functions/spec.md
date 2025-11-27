# edge-functions Specification

## Purpose

Edge functions provide external service integrations for the database-first architecture. They handle provider connections (LLM, embeddings, Nominatim) and abstract secrets management, allowing the database to call external services without exposing API keys.

All edge functions are called ONLY by the database via http extension. Frontend does NOT call edge functions.

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

- **WHEN** called with valid parameters (prompt required; model, format, options optional)
- **THEN** it returns generated text and hides provider secrets

#### Scenario: Error handling

- **WHEN** provider or input errors occur
- **THEN** standardized errors are returned with no sensitive data leaked

#### Scenario: Configuration

- **WHEN** changing providers
- **THEN** configuration/env selects providers without code changes

### Requirement: place-enrichment Edge Function

The system SHALL provide an edge function to fetch place data by OSM ID and extract traits for submissions.

#### Scenario: Successful enrichment

- **WHEN** called with a valid osm_id (e.g., "way/5013364")
- **THEN** it returns normalized Nominatim data and an extracted trait list in structured form

#### Scenario: Error handling

- **WHEN** Nominatim lookup or trait extraction fails
- **THEN** standardized errors are returned without leaking secrets

#### Scenario: Security

- **WHEN** responding
- **THEN** only necessary place/trait data is returned; no secrets are exposed
