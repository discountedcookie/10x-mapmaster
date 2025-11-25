# Game Core Specification

## Purpose

Define the core game mechanics, flows, and state transitions for the geographic guessing game.

---

## Requirements

### Requirement: Game Initialization

The system SHALL create a new game session when a player submits a place description.

#### Scenario: Start game with description

- **WHEN** player submits a description (max 200 characters)
- **THEN** system creates a game session with status `active`
- **AND** generates an embedding from the description
- **AND** finds initial candidate places via semantic similarity
- **AND** determines first action (question or guess)

#### Scenario: Start game with language preference

- **WHEN** player submits description with language code (e.g., "en", "pl")
- **THEN** system stores language preference for LLM-generated questions

---

### Requirement: Turn Processing

The system SHALL process player answers and update game state each turn.

#### Scenario: Answer a question

- **WHEN** player answers "yes", "no", or "not sure" to a question
- **THEN** system records the answer
- **AND** updates candidate scores based on answer
- **AND** increments turn count
- **AND** determines next action

#### Scenario: Confirm a guess

- **WHEN** player answers "yes" or "no" to a guess
- **THEN** system records the answer
- **AND** if "yes", marks game as won
- **AND** if "no", eliminates guessed place and continues

#### Scenario: Not sure answer

- **WHEN** player answers "not sure"
- **THEN** system records answer for LLM context
- **AND** turn count increments (same cost as yes/no)
- **AND** no score adjustments applied to candidates

---

### Requirement: Confidence-Based Guessing

The system SHALL guess a place when confidence thresholds are met.

#### Scenario: High confidence triggers guess

- **WHEN** top probability, margin, AND entropy thresholds all pass
- **THEN** system asks "Is it [Place Name]?"

#### Scenario: Single candidate remaining

- **WHEN** only one candidate remains
- **THEN** system automatically guesses that candidate

#### Scenario: Thresholds not met

- **WHEN** any confidence threshold fails
- **THEN** system asks another question (if turns remain)

---

### Requirement: Question Selection

The system SHALL select questions that maximally discriminate between candidates.

#### Scenario: Select best splitting question

- **WHEN** system needs to ask a question
- **THEN** selects trait/region that splits candidates closest to 50/50
- **AND** generates natural language question via LLM

#### Scenario: Geographic vs semantic question

- **WHEN** geographic question has high split quality
- **THEN** system prefers geographic question (binary filter is simpler)
- **OTHERWISE** asks semantic trait question

#### Scenario: No good questions available

- **WHEN** no trait meets minimum split quality
- **THEN** system selects best available option anyway

---

### Requirement: Game End Conditions

The system SHALL end games appropriately based on outcomes.

#### Scenario: Correct guess (win)

- **WHEN** player confirms guess is correct
- **THEN** game status changes to `won`
- **AND** learning is triggered (registered) or pending review (anonymous)

#### Scenario: Max turns reached

- **WHEN** turn count reaches max_turns without correct guess
- **THEN** game status changes to `needs_submission`
- **AND** system prompts player to submit correct place

#### Scenario: No candidates remaining

- **WHEN** all candidates eliminated
- **THEN** game status changes to `needs_submission`

---

### Requirement: Place Submission

The system SHALL allow players to submit the correct place after giving up.

#### Scenario: Submit existing place

- **WHEN** player submits place that exists in database
- **THEN** system links session to place
- **AND** extracts new traits from player description
- **AND** game status changes to `ended`

#### Scenario: Submit new place

- **WHEN** player submits place not in database
- **THEN** system creates place via Nominatim enrichment
- **AND** extracts traits from OSM data
- **AND** new place marked pending review
- **AND** game status changes to `ended`

---

### Requirement: Game States

The system SHALL maintain clear game state transitions.

#### Scenario: Active state

- **WHEN** game is in progress
- **THEN** status is `active`
- **AND** system processes questions/guesses

#### Scenario: Won state

- **WHEN** player confirms correct guess
- **THEN** status is `won`
- **AND** game is complete

#### Scenario: Needs submission state

- **WHEN** max turns reached or no candidates
- **THEN** status is `needs_submission`
- **AND** awaits player place submission

#### Scenario: Ended state

- **WHEN** player submits place after giving up
- **THEN** status is `ended`
- **AND** game is complete

---

### Requirement: Learning System

The system SHALL learn from completed games to improve future performance.

#### Scenario: Registered user learning

- **WHEN** registered user completes game
- **THEN** learning triggers immediately
- **AND** traits extracted from description
- **AND** place embedding regenerated

#### Scenario: Anonymous user learning

- **WHEN** anonymous user completes game
- **THEN** session marked pending review
- **AND** learning deferred until admin approval

#### Scenario: Account upgrade

- **WHEN** anonymous user registers account
- **THEN** all their pending sessions auto-approved
- **AND** accumulated learning applied via triggers

---

### Requirement: Session Cleanup

The system SHALL clean up abandoned sessions.

#### Scenario: Abandoned session deletion

- **WHEN** active session has no activity for 24 hours
- **THEN** session is hard deleted by cron job
- **AND** associated answers cascade deleted
