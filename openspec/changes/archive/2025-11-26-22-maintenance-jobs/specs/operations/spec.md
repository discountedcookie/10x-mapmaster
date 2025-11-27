## ADDED Requirements

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
