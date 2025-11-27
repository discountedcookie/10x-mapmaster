## ADDED Requirements

### Requirement: Game Sessions Storage

The system SHALL store game sessions with lifecycle, embedding, and pending review metadata.

#### Scenario: Session fields

- **WHEN** a session is stored
- **THEN** it has id, user_id, description (<=200 chars), language_code, embedding_id, next_turn JSONB, status enum, pending_review, was_correct, place_id, timestamps

#### Scenario: Constraints and indexes

- **WHEN** validating sessions
- **THEN** description length is enforced; status enum constrained; indexes exist on user_id/status as needed

#### Scenario: Access

- **WHEN** storing references
- **THEN** FKs to embeddings/places are maintained; user ownership is tracked
