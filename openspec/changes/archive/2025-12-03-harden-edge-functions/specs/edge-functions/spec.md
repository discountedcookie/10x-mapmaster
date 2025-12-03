## ADDED Requirements

### Requirement: Retry Logic

Edge functions SHALL retry transient failures with exponential backoff.

#### Scenario: Transient API failure

- **WHEN** an external API returns a 5xx error or network error
- **THEN** the request is retried up to 3 times
- **AND** each retry waits exponentially longer (1s, 2s, 4s)
- **AND** if all retries fail, a structured error is returned

#### Scenario: Permanent API failure

- **WHEN** an external API returns a 4xx error
- **THEN** the request is NOT retried
- **AND** a structured error is returned immediately

### Requirement: Request Timeouts

Edge functions SHALL timeout external requests after a configurable duration.

#### Scenario: Slow external API

- **WHEN** an external API does not respond within 30 seconds
- **THEN** the request is aborted
- **AND** a timeout error is returned
- **AND** retries may be attempted

### Requirement: Structured Error Responses

Edge functions SHALL return structured error responses for all failure modes.

#### Scenario: Error response format

- **WHEN** any error occurs
- **THEN** the response includes `error.code`, `error.message`, and `error.retryable`
- **AND** the HTTP status code matches the error type
