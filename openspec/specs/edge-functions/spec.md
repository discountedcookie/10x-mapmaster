# Edge Functions Specification

## Purpose

Define the Supabase Edge Functions that integrate with external services (LLM, embeddings, Nominatim). Edge functions are called only by the database, never directly by frontend.

---

## Requirements

### Requirement: Provider-Agnostic Architecture

The system SHALL abstract provider differences in edge functions.

#### Scenario: Environment-based provider selection

- **WHEN** edge function executes
- **THEN** reads LLM_PROVIDER and EMBEDDING_PROVIDER from environment
- **AND** connects to appropriate provider (Ollama/Supabase/external)

#### Scenario: Consistent output

- **WHEN** embedding generated
- **THEN** always returns 384d vector regardless of provider

#### Scenario: Secret management

- **WHEN** API keys needed
- **THEN** read from Supabase Vault
- **AND** database never sees secrets

---

### Requirement: Generate Embedding Function

The system SHALL provide embedding generation via edge function.

#### Scenario: Generate embedding

- **WHEN** POST /functions/v1/generate-embedding called with text
- **THEN** returns 384d vector representation

#### Scenario: Provider handling

- **WHEN** embedding requested
- **THEN** edge function routes to configured provider
- **AND** returns consistent format

---

### Requirement: Call LLM Function

The system SHALL provide LLM calls via edge function.

#### Scenario: Call LLM

- **WHEN** POST /functions/v1/call-llm called with model, temperature, max_tokens, prompt
- **THEN** returns generated text response

#### Scenario: Trait extraction

- **WHEN** database calls for trait extraction
- **THEN** LLM extracts trait descriptions from provided context

#### Scenario: Question generation

- **WHEN** database calls for question generation
- **THEN** LLM generates natural language yes/no question in target language

---

### Requirement: Fetch Place Function

The system SHALL provide Nominatim lookup via edge function.

#### Scenario: Fetch place data

- **WHEN** GET /functions/v1/fetch-place/{osm_id} called
- **THEN** returns name, display_name, lat, lng, boundingbox, extratags, address, geojson

#### Scenario: Geometry included

- **WHEN** place has polygon geometry
- **THEN** geojson field contains polygon data

---

### Requirement: LLM Context Composition

The system SHALL provide rich context to LLM for generation.

#### Scenario: Question generation context

- **WHEN** generating a question
- **THEN** LLM receives: player description, previous Q&A, current candidates, geographic regions, selected trait/region, language code

#### Scenario: Trait extraction context

- **WHEN** extracting traits
- **THEN** LLM receives: Nominatim data (extratags, address) and optionally player descriptions

---

### Requirement: LLM Boundaries

The system SHALL limit LLM responsibilities to text generation only.

#### Scenario: LLM does not make decisions

- **WHEN** LLM called
- **THEN** only generates text (questions, trait lists)
- **AND** does not select traits, calculate scores, or make gameplay decisions

#### Scenario: Database controls logic

- **WHEN** game decision needed
- **THEN** database logic determines what to do
- **AND** LLM only translates decision to natural language

---

### Requirement: Development vs Production

The system SHALL support different providers per environment.

#### Scenario: Development environment

- **WHEN** running locally
- **THEN** uses Ollama for embeddings and LLM

#### Scenario: Production environment

- **WHEN** running in production
- **THEN** uses Supabase gte-small for embeddings
- **AND** configured LLM provider for text generation

#### Scenario: Consistent behavior

- **WHEN** same model runs in both environments
- **THEN** behavior is consistent between development and production
