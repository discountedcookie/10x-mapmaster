## MODIFIED Requirements

### Requirement: submit_place RPC

The system SHALL expose submit_place to handle place submission after give up, enrichment, and review.

#### Scenario: Successful submission

- **WHEN** called with a valid session in needs_submission and a valid osm_id
- **THEN** enrichment runs, place is created/updated, session links to place, pending_review is set per user type, and learning is triggered if auto-approved.

#### Scenario: Invalid session state

- **WHEN** submit_place is called for a session that is not in needs_submission
- **THEN** it returns a standardized error_response and does not modify places or the session.

#### Scenario: Invalid ownership

- **WHEN** submit_place is called for a session not owned by the caller
- **THEN** it returns a standardized error_response and leaves state unchanged.

#### Scenario: Invalid osm_id

- **WHEN** submit_place is called with a missing or invalid osm_id
- **THEN** it returns a standardized error_response and does not create or link a place.

#### Scenario: Rate limiting

- **WHEN** the rate limit for submit_place is exceeded
- **THEN** the function returns a standardized error_response and does not perform enrichment or updates.
