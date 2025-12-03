# game-core Specification

## Purpose

Defines the public RPC functions (`start_game`, `play_turn`, `submit_place`) that form the API for gameplay. These are the only entry points for game interactions - all game logic executes server-side in PostgreSQL.

## Requirements

### Requirement: start_game RPC

The system SHALL expose start_game to initialize a session, embed the description, seed candidates, and set the first turn.

#### Scenario: Successful start

- **WHEN** called with valid description and language_code
- **THEN** a session is created with embedding_id, initial candidates seeded, next_turn set, and session_id returned

#### Scenario: Validation and rate limiting

- **WHEN** input is invalid or rate limit exceeded
- **THEN** the function returns standardized error_response and does not create a session

#### Scenario: Security and ownership

- **WHEN** start_game runs
- **THEN** it uses hardened search_path, appropriate auth checks, and relies on RLS for session ownership

### Requirement: play_turn RPC

The system SHALL expose play_turn to record answers, update candidates, and set the next action.

#### Scenario: Successful turn

- **WHEN** called with a valid session_id and answer
- **THEN** the answer is recorded, candidates updated, next_turn JSON set, and session_id returned

#### Scenario: Validation and errors

- **WHEN** input is invalid, session not found/owned, or rate limits exceeded
- **THEN** the function returns standardized error_response and leaves state unchanged

#### Scenario: Security and ownership

- **WHEN** play_turn runs
- **THEN** it enforces ownership via RLS/auth guards and uses hardened search_path

### Requirement: submit_place RPC

The system SHALL expose submit_place to handle place submission after give up, enrichment, and review.

#### Scenario: Successful submission

- **WHEN** called with a valid session in needs_submission and a valid osm_id
- **THEN** enrichment runs, place is created/updated, session links to place, pending_review set per user type, and learning triggered if auto-approved

#### Scenario: Invalid session state

- **WHEN** submit_place is called for a session that is not in needs_submission
- **THEN** it returns a standardized error_response and does not modify places or the session

#### Scenario: Invalid ownership

- **WHEN** submit_place is called for a session not owned by the caller
- **THEN** it returns a standardized error_response and leaves state unchanged

#### Scenario: Invalid osm_id

- **WHEN** submit_place is called with a missing or invalid osm_id
- **THEN** it returns a standardized error_response and does not create or link a place

#### Scenario: Rate limiting

- **WHEN** the rate limit for submit_place is exceeded
- **THEN** the function returns a standardized error_response and does not perform enrichment or updates

#### Scenario: Security and ownership

- **WHEN** submit_place runs
- **THEN** it enforces ownership/auth, uses hardened search_path, and relies on RLS for session isolation
