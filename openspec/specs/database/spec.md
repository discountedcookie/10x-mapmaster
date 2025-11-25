# Database Specification

## Purpose

Define the PostgreSQL schema, data model, security policies, and database functions for the geographic guessing game. All business logic lives in the database.

---

## Requirements

### Requirement: Database-First Architecture

The system SHALL implement all business logic in PostgreSQL, with frontend as presentation only.

#### Scenario: Game logic in database

- **WHEN** game operations occur (start, play, submit)
- **THEN** all logic executes in PostgreSQL functions
- **AND** frontend only calls RPC and displays results

#### Scenario: Frontend restrictions

- **WHEN** frontend code exists
- **THEN** it contains no game logic, scoring, or calculations
- **AND** accesses data only via RPC calls

---

### Requirement: Core Data Tables

The system SHALL maintain tables for places, traits, embeddings, and game data.

#### Scenario: Places table

- **WHEN** a place is stored
- **THEN** it has id, name, lat, lng, embedding_id, geometry, pending_review flag

#### Scenario: Traits table

- **WHEN** a trait is stored
- **THEN** it has id, clause (text), and embedding_id

#### Scenario: Place-traits relationship

- **WHEN** places and traits are related
- **THEN** many-to-many via place_traits join table

#### Scenario: Embeddings table

- **WHEN** an embedding is stored
- **THEN** it has id, source_text, and 384d vector

#### Scenario: Game sessions table

- **WHEN** a game session is stored
- **THEN** it has id, user_id, description (max 200 chars), embedding_id, next_turn (jsonb), status enum, pending_review, was_correct, place_id, timestamps

#### Scenario: Game answers table

- **WHEN** an answer is stored
- **THEN** it has id, session_id, and exactly ONE of: trait_id, geographic_region_id, or place_id
- **AND** answer value is 'yes', 'no', or 'not_sure'

#### Scenario: Geographic regions table

- **WHEN** a region is stored
- **THEN** it has id, name, level, and PostGIS geometry

---

### Requirement: Configuration Tables

The system SHALL store runtime configuration in database tables.

#### Scenario: Public config

- **WHEN** client-visible settings are needed
- **THEN** stored in public.config (key-value)
- **AND** accessible via SELECT for authenticated users

#### Scenario: Private config

- **WHEN** server-only settings are needed (scoring, thresholds, prompts)
- **THEN** stored in game_logic.config (key-value)
- **AND** accessible only by SECURITY DEFINER functions

---

### Requirement: Public RPC Functions

The system SHALL expose exactly three public RPC functions for game operations.

#### Scenario: start_game function

- **WHEN** called with description and language_code
- **THEN** creates session, generates embedding, finds candidates
- **AND** returns session_id

#### Scenario: play_turn function

- **WHEN** called with session_id and answer enum
- **THEN** records answer, updates candidates, determines next action
- **AND** returns session_id

#### Scenario: submit_place function

- **WHEN** called with session_id and osm_id
- **THEN** enriches place via edge function, extracts traits
- **AND** returns void on success

---

### Requirement: Row Level Security

The system SHALL enforce data access via RLS policies on all tables.

#### Scenario: User session isolation

- **WHEN** user queries game_sessions
- **THEN** sees only their own sessions (user_id = auth.uid())

#### Scenario: User answer isolation

- **WHEN** user queries game_answers
- **THEN** sees only answers for their sessions

#### Scenario: Public data access

- **WHEN** user queries places, traits, geographic_regions
- **THEN** sees all approved (non-pending) records

#### Scenario: Config access

- **WHEN** user queries public.config
- **THEN** can SELECT all rows
- **AND** cannot access game_logic.config directly

---

### Requirement: SECURITY DEFINER Functions

The system SHALL validate authentication in all privileged functions.

#### Scenario: Auth validation

- **WHEN** SECURITY DEFINER function executes
- **THEN** validates auth.uid() IS NOT NULL
- **AND** returns error if not authenticated

#### Scenario: Session ownership validation

- **WHEN** function operates on a session
- **THEN** validates session belongs to auth.uid()

---

### Requirement: Schema Organization

The system SHALL organize database objects into schemas by visibility.

#### Scenario: Public schema

- **WHEN** data/functions are client-accessible
- **THEN** placed in public schema
- **AND** protected by RLS policies

#### Scenario: Game logic schema

- **WHEN** functions/data are server-only
- **THEN** placed in game_logic schema
- **AND** not directly accessible to clients

---

### Requirement: Stats Views

The system SHALL provide aggregated statistics via views.

#### Scenario: User stats view

- **WHEN** user queries public.user_stats
- **THEN** sees games_played, games_won, win_rate, avg_turns_to_win, places_added, last_played_at
- **AND** RLS ensures only own row visible

#### Scenario: Global stats view

- **WHEN** user queries public.global_stats
- **THEN** sees total_games, games_last_24h, total_users, total_places, total_traits, overall_win_rate, avg_turns_to_win
- **AND** accessible to all authenticated users

---

### Requirement: Learning Triggers

The system SHALL trigger learning via database triggers.

#### Scenario: Approval trigger

- **WHEN** game_sessions.pending_review changes to false
- **THEN** trigger fires regenerate_place_traits(place_id)

#### Scenario: Trait regeneration

- **WHEN** regenerate_place_traits executes
- **THEN** queries all approved sessions for the place
- **AND** combines Nominatim data with session descriptions
- **AND** LLM extracts complete trait list
- **AND** replaces place_traits entirely
- **AND** regenerates place embedding

---

### Requirement: Rate Limiting

The system SHALL enforce rate limits via database functions.

#### Scenario: Rate limit check

- **WHEN** RPC function called
- **THEN** check_rate_limit(user_id, action) validates request count
- **AND** returns error if exceeded

#### Scenario: Rate limit logging

- **WHEN** request allowed
- **THEN** logged to rate_limit_log table

#### Scenario: Rate limit cleanup

- **WHEN** pg_cron runs
- **THEN** deletes entries older than rate limit window

---

### Requirement: Error Response Structure

The system SHALL return standardized error responses.

#### Scenario: Error response format

- **WHEN** function returns error
- **THEN** uses error_response type with error_code, http_status, optional details

#### Scenario: Error codes

- **WHEN** error occurs
- **THEN** uses enumerated error_code for i18n translation lookup
