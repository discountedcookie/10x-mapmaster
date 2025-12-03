# Database Spec Delta: Async Trait Extraction

## ADDED Requirements

### Requirement: Trait Extraction Queue

The system SHALL process trait extraction asynchronously via pgmq message queue.

#### Scenario: Game Win Enqueues Extraction

- **WHEN** a game session's `was_correct` changes to TRUE
- **THEN** a message is enqueued to `trait_extraction` queue with place_id
- **AND** pg_net fires HTTP to process-trait-extraction edge function
- **AND** the triggering transaction completes without waiting for extraction

#### Scenario: Immediate Processing via Edge Function

- **WHEN** the process-trait-extraction edge function receives a request
- **THEN** it reads the place_id from the request
- **AND** calls `update_place_traits` RPC
- **AND** deletes the message from queue on success

#### Scenario: Backup Processing via pg_cron

- **WHEN** a message has been in queue for more than 60 seconds
- **THEN** the pg_cron backup job processes it
- **AND** calls `update_place_traits` directly
- **AND** deletes/archives the message

### Requirement: pgmq Extension

The system SHALL use the pgmq extension for message queue functionality.

#### Scenario: Extension Availability

- **WHEN** the database is initialized
- **THEN** the pgmq extension is enabled
- **AND** the `trait_extraction` queue exists

### Requirement: Non-Blocking Trigger

The game completion trigger SHALL NOT block on trait extraction.

#### Scenario: Fast Transaction Commit

- **WHEN** a user confirms a correct guess
- **THEN** the transaction commits in under 100ms
- **AND** trait extraction happens asynchronously afterward

## MODIFIED Requirements

### Requirement: Place Enrichment Trigger (Modified)

The `enrich_place_on_session_complete` trigger SHALL enqueue async extraction instead of blocking.

#### Scenario: Async Enqueue Pattern

- **WHEN** a game session completes with correct guess
- **THEN** the trigger calls `enqueue_trait_extraction(place_id)`
- **AND** returns immediately without HTTP calls
- **AND** the game state is committed before extraction runs
