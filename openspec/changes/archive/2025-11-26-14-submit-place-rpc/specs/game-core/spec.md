## ADDED Requirements

### Requirement: submit_place RPC

The system SHALL expose submit_place to handle place submission after give up, enrichment, and review.

#### Scenario: Successful submission

- **WHEN** called with a valid session in needs_submission and a valid osm_id
- **THEN** enrichment runs, place is created/updated, session links to place, pending_review set per user type, and learning triggered if auto-approved

#### Scenario: Validation and errors

- **WHEN** session is not in needs_submission, not owned, invalid osm_id, or rate limit exceeded
- **THEN** the function returns standardized error_response and does not commit changes

#### Scenario: Security and ownership

- **WHEN** submit_place runs
- **THEN** it enforces ownership/auth, uses hardened search_path, and relies on RLS for session isolation
