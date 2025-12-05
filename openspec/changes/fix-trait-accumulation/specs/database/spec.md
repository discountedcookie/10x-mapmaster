# Database Spec: Fix Trait Accumulation

## MODIFIED Requirements

### Requirement: Trait Knowledge Curation

The system SHALL accumulate a place's traits over time, preserving valuable knowledge while incorporating new learnings.

#### Scenario: Trait accumulation

- **WHEN** update_place_traits(place_id) runs for a place with existing traits
- **THEN** new traits from the LLM response are added to the place
- **AND** existing traits are NOT deleted before insertion
- **AND** exact duplicates are prevented via ON CONFLICT DO NOTHING

#### Scenario: Knowledge curation by LLM

- **WHEN** the LLM receives existing traits and new information
- **THEN** it curates the knowledge base (keep/add/remove/consolidate)
- **AND** it returns a brief explanation of changes made
- **AND** it stays within the configured trait limit (30)

#### Scenario: Human-readable traits

- **WHEN** traits are generated
- **THEN** each trait is a complete, naturally readable statement
- **AND** traits are suitable for display as "What I know about this place"
- **AND** traits include specific facts (measurements, dates, materials, etc.)

#### Scenario: Robustness

- **WHEN** LLM extraction fails or returns invalid data
- **THEN** existing traits are preserved (no deletion occurs)
- **AND** error is logged with warning

### Requirement: Nominatim Data Formatting

The system SHALL format Nominatim data as readable text for LLM consumption.

#### Scenario: Text formatting

- **WHEN** building the LLM prompt
- **THEN** Nominatim extratags are formatted as `key: value` lines
- **AND** raw JSON is NOT passed to the LLM
- **AND** category is formatted as `class/type`

### Requirement: Trait Extraction Queue

The system SHALL process trait extraction messages sequentially.

#### Scenario: Single worker processing

- **WHEN** multiple extractions are queued
- **THEN** the edge function processes one message at a time
- **AND** each extraction completes before the next begins
- **AND** each extraction sees the previous extraction's results

#### Scenario: Message acknowledgment

- **WHEN** an extraction completes successfully
- **THEN** the message is archived from the queue
- **WHEN** an extraction fails
- **THEN** the message remains in the queue for retry

## Configuration

| Key                               | Value          | Description              |
| --------------------------------- | -------------- | ------------------------ |
| `llm.trait_extraction.max_traits` | 30             | Maximum traits per place |
| `llm.trait_extraction.prompt`     | (see tasks.md) | Curation-focused prompt  |

## DEFERRED to Phase 2

The following requirements are out of scope for this change:

- Semantic deduplication of similar traits (embedding similarity)
- Configurable similarity thresholds
- Trait categorization/grouping
- Per-place parallel processing
