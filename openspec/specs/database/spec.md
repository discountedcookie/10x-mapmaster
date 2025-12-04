# database Specification

## Purpose

Defines the database schema, authentication model, RLS policies, configuration tables, and data types. This is the foundation for the database-first architecture where all business logic resides.
## Requirements
### Requirement: Auth Model and Security Posture

The system SHALL define and enforce an auth model covering anonymous, registered, and service roles, and prescribe SECURITY DEFINER and RLS guardrails.

#### Scenario: Auth personas

- **WHEN** the database evaluates access
- **THEN** it recognizes anonymous users and registered users as having non-null UUID auth.uid() values, and service_role with elevated privileges.

#### Scenario: RLS posture

- **WHEN** applying RLS
- **THEN** user-owned tables restrict by auth.uid(); public data is read-open; private tables are blocked except to service_role, without relying on user_id IS NULL branches.

### Requirement: Schemas and Extensions

The system SHALL define required schemas and install core extensions and types for the database.

#### Scenario: Schemas and search_path

- **WHEN** deploying the database
- **THEN** schemas extensions, public, and game_logic exist and functions set search_path explicitly

#### Scenario: Extensions installed

- **WHEN** extensions are provisioned
- **THEN** pgvector (384d), PostGIS, and pg_cron are installed in the extensions schema and available

#### Scenario: Types and enums

- **WHEN** shared types are needed
- **THEN** enums (e.g., status, answer_value) and any composite types are defined centrally

### Requirement: Configuration Tables

The system SHALL store configuration in separate public and private tables with appropriate access controls.

#### Scenario: Public config access

- **WHEN** authenticated users query public.config
- **THEN** they can read key/value pairs intended for clients

#### Scenario: Private config protection

- **WHEN** accessing game_logic.config
- **THEN** only SECURITY DEFINER functions or service_role can read/write; clients cannot access directly

#### Scenario: Config integrity

- **WHEN** inserting config rows
- **THEN** keys are unique and values are non-null JSON

### Requirement: Embeddings Storage

The system SHALL store text embeddings with required constraints and indexes for semantic similarity.

#### Scenario: Embedding persistence

- **WHEN** an embedding is stored
- **THEN** it records id, source_text, 384d vector, and timestamps

#### Scenario: Indexing

- **WHEN** querying embeddings by similarity
- **THEN** an HNSW index exists on the embedding column using vector_ip_ops

#### Scenario: Access control

- **WHEN** accessing embeddings
- **THEN** only authorized functions/service_role can read/write embeddings per RLS/policies

### Requirement: Traits and Place-Trait Association

The system SHALL store canonical traits and link them to places via a join table.

#### Scenario: Trait definition

- **WHEN** a trait is stored
- **THEN** it has id, clause, optional embedding_id, and timestamps

#### Scenario: Place-trait relationship

- **WHEN** linking places to traits
- **THEN** a join table with PK(place_id, trait_id) and FKs to places/traits is used with appropriate indexes

#### Scenario: Access

- **WHEN** reading traits and associations
- **THEN** they are readable by all; writes are restricted to authorized roles

### Requirement: Places Storage with Geometry

The system SHALL store places with geometry, embeddings, and review status for gameplay and visualization.

#### Scenario: Place fields

- **WHEN** a place is stored
- **THEN** it has id, name, osm_id (unique), lat, lng, geom, embedding_id, pending_review, timestamps

#### Scenario: Indexing and constraints

- **WHEN** querying places
- **THEN** GIST index exists on geom; unique constraint on osm_id; indexes on embedding_id/name as appropriate

#### Scenario: Access

- **WHEN** reading places
- **THEN** data is readable publicly; writes are restricted to authorized roles

### Requirement: Geographic Regions

The system SHALL store geographic regions with geometry and level metadata for spatial filtering.

#### Scenario: Region fields

- **WHEN** a region is stored
- **THEN** it has id, name, level, geometry, and timestamps

#### Scenario: Constraints and indexes

- **WHEN** validating regions
- **THEN** level is constrained to allowed values; GIST index exists on geometry

#### Scenario: Access

- **WHEN** reading regions
- **THEN** data is publicly readable; writes restricted to authorized roles

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

### Requirement: Game Answers Table

The system SHALL store answers with exactly one of trait_id, geographic_region_id, or place_id populated.

#### Scenario: One-of enforcement

- **WHEN** an answer is stored
- **THEN** exactly one of trait_id, geographic_region_id, or place_id is non-null via CHECK

#### Scenario: Relationships and cleanup

- **WHEN** sessions or referenced entities are deleted
- **THEN** FKs cascade appropriately to keep answers consistent

#### Scenario: Query performance

- **WHEN** querying answers
- **THEN** indexes exist on session_id and a supporting index for polymorphic lookups

### Requirement: Session and Answer RLS

The system SHALL enforce row-level security for game_sessions and game_answers based on ownership.

#### Scenario: UUID-based ownership

- **WHEN** any user (anonymous or registered) accesses sessions/answers
- **THEN** they can only see and modify rows where game_sessions.user_id = auth.uid().

#### Scenario: Service role access

- **WHEN** service_role accesses sessions/answers
- **THEN** it can manage all rows for maintenance and internal operations.

### Requirement: Learning Trigger on Approval

The system SHALL trigger trait regeneration when a session is approved (pending_review becomes false).

#### Scenario: Approval firing

- **WHEN** game_sessions.pending_review transitions from TRUE to FALSE and place_id is set
- **THEN** regenerate_place_traits(place_id) is invoked

#### Scenario: No-op conditions

- **WHEN** place_id is NULL or pending_review does not change
- **THEN** the trigger does not call regeneration

### Requirement: Trait Regeneration

The system SHALL regenerate a place's traits and embedding using enrichment data and approved session descriptions.

#### Scenario: Full regeneration

- **WHEN** regenerate_place_traits(place_id) runs
- **THEN** it combines place enrichment data and all approved session descriptions to extract traits, replaces place_traits, and regenerates the place embedding

#### Scenario: Robustness

- **WHEN** required data is missing or extraction fails
- **THEN** the function handles errors explicitly and avoids partial updates

### Requirement: Stats Views

The system SHALL provide user and global statistics via read-only views with proper access controls.

#### Scenario: User stats

- **WHEN** a user queries user_stats
- **THEN** they see only their row with games_played, games_won, win_rate, avg_turns_to_win, places_added, last_played_at

#### Scenario: Global stats

- **WHEN** a user queries global_stats
- **THEN** they see aggregated columns (total_games, games_last_24h, total_users, total_places, total_traits, overall_win_rate, avg_turns_to_win) if authenticated

### Requirement: Server-Only Algorithm Configuration

The system SHALL store algorithm configuration in a server-only schema inaccessible to clients.

#### Scenario: Config table isolation

- **WHEN** algorithm parameters are stored
- **THEN** they reside in `game_logic.config` with RLS blocking client access

#### Scenario: Hierarchical key naming

- **WHEN** config values are accessed
- **THEN** keys use dot-notation hierarchy (e.g., `confidence.top_prob_threshold`)

#### Scenario: Consistent access pattern

- **WHEN** game logic functions read configuration
- **THEN** they use `game_logic.get_config(key)` helper function

### Requirement: Trait Extraction Queue

The system SHALL process trait extraction asynchronously via pgmq message queue.

#### Scenario: Game Win Enqueues Extraction

- **WHEN** a game session's `was_correct` changes to TRUE
- **THEN** a message is enqueued to `trait_extraction` queue with place_id
- **AND** pg_net fires HTTP to process-trait-extraction edge function
- **AND** the triggering transaction completes without waiting for extraction

#### Scenario: Immediate Processing via Edge Function

- **WHEN** the process-trait-extraction edge function receives a request
- **THEN** it reads the place_id from the request
- **AND** calls `update_place_traits` RPC
- **AND** deletes the message from queue on success

#### Scenario: Backup Processing via pg_cron

- **WHEN** a message has been in queue for more than 60 seconds
- **THEN** the pg_cron backup job processes it
- **AND** calls `update_place_traits` directly
- **AND** deletes/archives the message

### Requirement: pgmq Extension

The system SHALL use the pgmq extension for message queue functionality.

#### Scenario: Extension Availability

- **WHEN** the database is initialized
- **THEN** the pgmq extension is enabled
- **AND** the `trait_extraction` queue exists

### Requirement: Non-Blocking Game Completion

The game completion trigger SHALL NOT block on trait extraction.

#### Scenario: Fast Transaction Commit

- **WHEN** a user confirms a correct guess
- **THEN** the transaction commits in under 100ms
- **AND** trait extraction happens asynchronously afterward

#### Scenario: Async Enqueue Pattern

- **WHEN** a game session completes with correct guess
- **THEN** the trigger calls `enqueue_trait_extraction(place_id)`
- **AND** returns immediately without HTTP calls
- **AND** the game state is committed before extraction runs

### Requirement: submit_place Database Behavior

The system SHALL implement submit_place as a database function that enforces ownership, session state, and enrichment side effects.

#### Scenario: Inputs and outputs

- **WHEN** the submit_place function is called
- **THEN** it accepts a session identifier and an osm_id, and returns either a success payload or a standardized error_response

#### Scenario: Side effects on success

- **WHEN** submit_place succeeds
- **THEN** a place row is created or updated, the session is linked to the place, pending_review and was_correct fields are set appropriately, and any learning triggers required by the database spec are invoked

#### Scenario: No side effects on error

- **WHEN** submit_place returns an error_response
- **THEN** it does not create or update place rows and does not change existing session state

### Requirement: Test Organization

Database tests SHALL be organized by domain, mirroring the `supabase/db/` directory structure.

#### Scenario: Test file naming convention

- **WHEN** creating a new database test file
- **THEN** the file name SHALL follow the pattern `test_{category}_{domain}.sql`
- **AND** `{category}` SHALL be one of: `tables`, `views`, `functions`, `schema`
- **AND** `{domain}` SHALL match the corresponding source file or directory name

#### Scenario: Test file contents

- **WHEN** a domain test file is created
- **THEN** it SHALL contain all tests for that domain including:
  - Schema validation (table/columns exist, correct types)
  - RLS policy tests (if applicable)
  - Behavioral tests (if applicable)

#### Scenario: Test discoverability

- **WHEN** a developer needs to find tests for a specific domain
- **THEN** they SHALL locate the test file by matching the domain name
- **AND** alphabetical sorting SHALL group files by category (tables, views, functions)

### Requirement: Database Test Resource Hygiene

The system SHALL structure database tests to avoid leaking TupleDesc or similar resources during pgTAP runs.

#### Scenario: Unused query results

- **WHEN** tests execute queries whose results are not inspected
- **THEN** they use PERFORM or equivalent patterns so that no TupleDesc resources are left open.

#### Scenario: Set-returning functions

- **WHEN** tests call set-returning functions
- **THEN** results are fully consumed or assigned in a way that prevents resource leaks.

#### Scenario: Clean test runs

- **WHEN** running the full pgTAP suite
- **THEN** no TupleDesc resource leak warnings are emitted as part of normal test execution.

