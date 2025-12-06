# Database Spec Deltas: fix-learning-trigger-errors

## MODIFIED Requirements

### Requirement: Trait Extraction Queue

The system SHALL process trait extraction asynchronously via pgmq message queue.

#### Scenario: Game Win Enqueues Extraction

- **WHEN** a game session's `was_correct` is set to TRUE (via INSERT or UPDATE)
- **AND** `place_id` is NOT NULL
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

## ADDED Requirements

### Requirement: Trait Extraction Fails Loudly

The system SHALL raise exceptions (not warnings) when trait extraction encounters configuration errors or processing failures, ensuring errors are visible and debuggable.

#### Scenario: Missing Supabase URL configuration

- **WHEN** `enqueue_trait_extraction` is called
- **AND** neither `app.supabase_url` nor `runtime.supabase_url` is configured
- **THEN** the function raises an EXCEPTION with message describing the missing config

#### Scenario: Missing service role key configuration

- **WHEN** `enqueue_trait_extraction` is called
- **AND** neither `app.service_role_key` nor `runtime.supabase_service_role_key` is configured
- **THEN** the function raises an EXCEPTION with message describing the missing config

#### Scenario: LLM trait parsing fails

- **WHEN** `update_place_traits` receives an unparseable LLM response
- **THEN** the function raises an EXCEPTION with the parsing error and response snippet

#### Scenario: No traits extracted

- **WHEN** `update_place_traits` completes but extracts zero traits
- **THEN** the function raises an EXCEPTION indicating no traits were found

### Requirement: Nominatim Fetch Failure is Non-Fatal

The system SHALL continue trait extraction even if Nominatim data fetch fails, using available data from the places table.

#### Scenario: Nominatim unavailable

- **WHEN** `update_place_traits` fails to fetch Nominatim data
- **THEN** the function logs a WARNING (not exception)
- **AND** continues processing with existing place data
