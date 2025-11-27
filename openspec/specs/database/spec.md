# database Specification

## Purpose

TBD - created by archiving change 01-auth-basics. Update Purpose after archive.
## Requirements
### Requirement: Auth Model and Security Posture

The system SHALL define and enforce an auth model covering anonymous, registered, and service roles, and prescribe SECURITY DEFINER and RLS guardrails.

#### Scenario: Auth personas

- **WHEN** the database evaluates access
- **THEN** it recognizes anonymous users (auth.uid() is NULL), registered users (auth.uid() set), and service_role with elevated privileges

#### Scenario: SECURITY DEFINER guardrails

- **WHEN** a SECURITY DEFINER function requires user context
- **THEN** it checks auth.uid() IS NOT NULL and sets an explicit search_path

#### Scenario: RLS posture

- **WHEN** applying RLS
- **THEN** user-owned tables restrict by auth.uid(); public data is read-open; private tables are blocked except to service_role

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

#### Scenario: Registered ownership

- **WHEN** a registered user accesses sessions/answers
- **THEN** they can only see and modify rows where game_sessions.user_id = auth.uid()

#### Scenario: Anonymous ownership

- **WHEN** an anonymous user (auth.uid() IS NULL) accesses
- **THEN** they can only see/modify rows whose user_id IS NULL

#### Scenario: Service role

- **WHEN** service_role accesses
- **THEN** it can manage all rows for maintenance and internal operations

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

