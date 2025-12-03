# edge-functions Specification

## Purpose

Edge functions provide external service integrations for the database-first architecture. They handle provider connections (LLM, embeddings, Nominatim) and abstract secrets management, allowing the database to call external services without exposing API keys.

All edge functions are called ONLY by the database via http extension. Frontend does NOT call edge functions.

## Design Principles

### Thin Wrappers, Not Smart Services

Edge functions are intentionally minimal. They:

- Accept parameters from the database
- Call the external API
- Return the result or error

They do NOT implement retries, circuit breakers, or complex error recovery.

### Resilience Lives in the Database

External API calls can fail. This project handles resilience at the database layer:

- **pgmq** (PostgreSQL Message Queue) handles async job processing with automatic retries
- **pg_cron** schedules retry attempts for failed operations
- **Database timeouts** control how long to wait for edge function responses

This design keeps edge functions stateless and simple. The database already has durable state, transaction guarantees, and scheduling capabilities - duplicating retry logic in edge functions would be redundant and could cause retry multiplication (edge function retries × database retries).

### Error Handling

Edge functions return structured errors so the database can log meaningful messages, but they don't try to recover from failures. If HuggingFace is down, the edge function fails fast and lets pgmq handle the retry.
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

### Requirement: LLM Trait Extraction

The system SHALL extract semantic traits from Nominatim data using LLM when enriching places.

#### Scenario: LLM extraction enabled

- **WHEN** place-enrichment runs with `llm.extraction.enabled` true
- **THEN** LLM generates trait descriptions from Nominatim fields (class, type, extratags)

#### Scenario: Fallback to rules

- **WHEN** LLM extraction fails or is disabled
- **THEN** rule-based extraction produces traits as fallback

#### Scenario: Trait merging

- **WHEN** both LLM and rule-based traits exist
- **THEN** they are merged with deduplication based on semantic similarity

### Requirement: Retry Logic

Edge functions SHALL retry transient failures with exponential backoff.

#### Scenario: Transient API failure

- **WHEN** an external API returns a 5xx error or network error
- **THEN** the request is retried up to 3 times
- **AND** each retry waits exponentially longer (1s, 2s, 4s)
- **AND** if all retries fail, a structured error is returned

#### Scenario: Permanent API failure

- **WHEN** an external API returns a 4xx error
- **THEN** the request is NOT retried
- **AND** a structured error is returned immediately

### Requirement: Request Timeouts

Edge functions SHALL timeout external requests after a configurable duration.

#### Scenario: Slow external API

- **WHEN** an external API does not respond within 30 seconds
- **THEN** the request is aborted
- **AND** a timeout error is returned
- **AND** retries may be attempted

### Requirement: Structured Error Responses

Edge functions SHALL return structured error responses for all failure modes.

#### Scenario: Error response format

- **WHEN** any error occurs
- **THEN** the response includes `error.code`, `error.message`, and `error.retryable`
- **AND** the HTTP status code matches the error type

