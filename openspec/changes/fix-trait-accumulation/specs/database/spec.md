## MODIFIED Requirements

### Requirement: Trait Regeneration

The system SHALL accumulate a place's traits from new session descriptions while preserving existing knowledge.

#### Scenario: Incremental trait addition

- **WHEN** update_place_traits(place_id) runs for a place with existing traits
- **THEN** new traits from the LLM response are added to the place
- **AND** existing traits are NOT deleted

#### Scenario: Semantic deduplication

- **WHEN** a newly extracted trait is semantically similar to an existing trait (embedding similarity > threshold)
- **THEN** the new trait is not added
- **AND** the existing trait is preserved unchanged

#### Scenario: Deduplication threshold

- **WHEN** checking for duplicate traits
- **THEN** similarity threshold is read from config key `traits.dedup_similarity_threshold`
- **AND** default threshold is 0.92

#### Scenario: Robustness

- **WHEN** LLM extraction fails or returns invalid data
- **THEN** existing traits are preserved (no deletion occurs)
- **AND** error is logged with warning

### Requirement: Trait Extraction Queue

The system SHALL process trait extraction sequentially per place via pgmq.

#### Scenario: Sequential per-place processing

- **WHEN** multiple extractions are queued for the same place_id
- **THEN** they are processed one at a time in order
- **AND** each extraction sees the previous extraction's results

#### Scenario: Per-place locking

- **WHEN** an extraction starts for a place
- **THEN** an advisory lock is acquired for that place_id
- **AND** concurrent extractions for the same place wait for the lock
- **AND** the lock is released when extraction completes

#### Scenario: Different places parallel

- **WHEN** extractions are queued for different place_ids
- **THEN** they may run in parallel
- **AND** no cross-place blocking occurs
