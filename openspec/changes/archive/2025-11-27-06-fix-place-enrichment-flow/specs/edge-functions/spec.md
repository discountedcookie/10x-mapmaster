## REMOVED Requirements

### Requirement: place-enrichment Edge Function

**Reason**: Violates database-first architecture. The database should call Nominatim directly and use `call-llm` for trait extraction.

**Migration**:

- Database calls Nominatim via `http` extension
- Database calls `call-llm` with `type: 'trait_extraction'` for LLM trait extraction
- Rule-based trait extraction moves to SQL

## MODIFIED Requirements

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
