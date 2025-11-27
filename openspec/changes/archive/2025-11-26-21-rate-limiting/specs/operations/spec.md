## ADDED Requirements

### Requirement: Rate Limiting

The system SHALL enforce per-user rate limits for RPC actions using database primitives.

#### Scenario: Limit enforcement

- **WHEN** check_rate_limit(user_id, action) is called
- **THEN** it counts requests within the configured window and raises an error when the limit is exceeded

#### Scenario: Logging

- **WHEN** a request is allowed
- **THEN** it is logged to rate_limit_log with user_id, action, and timestamp

#### Scenario: Configuration

- **WHEN** limits are not explicitly set
- **THEN** defaults for start_game, play_turn, and submit_place are applied from config
