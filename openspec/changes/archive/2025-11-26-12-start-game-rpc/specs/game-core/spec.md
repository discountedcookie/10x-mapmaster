## ADDED Requirements

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
