## ADDED Requirements

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
