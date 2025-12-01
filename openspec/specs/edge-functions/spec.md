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

The system SHALL provide an edge function to call LLMs for text generation and structured extraction with configurable providers.

#### Scenario: Successful LLM call

- **WHEN** called with valid parameters (type required; prompt, place_name, nominatim_data as needed)
- **THEN** it returns generated text or structured data and hides provider secrets

#### Scenario: Question generation

- **WHEN** called with `type: 'question_generation'` and trait/region context
- **THEN** it returns natural language question text

#### Scenario: Trait extraction

- **WHEN** called with `type: 'trait_extraction'` and Nominatim data
- **THEN** it returns structured traits array with id, category, clause fields

#### Scenario: Error handling

- **WHEN** provider or input errors occur
- **THEN** standardized errors are returned with no sensitive data leaked

#### Scenario: Configuration

- **WHEN** changing providers
- **THEN** configuration/env selects providers without code changes
