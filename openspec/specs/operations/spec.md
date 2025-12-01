# operations Specification

## Purpose

Defines operational concerns including rate limiting, maintenance jobs, and monitoring. These ensure the system remains performant and protected from abuse.

## Requirements

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

### Requirement: Maintenance Jobs

The system SHALL automate cleanup for rate limiting logs and abandoned sessions using pg_cron.

#### Scenario: Rate limit cleanup

- **WHEN** pg_cron runs the rate-limit cleanup job
- **THEN** entries older than the configured window are deleted from rate_limit_log

#### Scenario: Abandoned session cleanup

- **WHEN** pg_cron runs the session cleanup job
- **THEN** sessions considered abandoned are removed according to the defined criteria

#### Scenario: Scheduling and permissions

- **WHEN** jobs execute
- **THEN** they run under appropriate privileges and on the defined schedule
