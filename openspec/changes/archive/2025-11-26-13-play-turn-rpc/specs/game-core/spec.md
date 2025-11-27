## ADDED Requirements

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
