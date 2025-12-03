## REMOVED Requirements

### Requirement: Public Config Table (REMOVED)

The `public.config` table is removed. All configuration now uses `game_logic.config` only.

## MODIFIED Requirements

### Requirement: Configuration Tables

The system SHALL store configuration in a server-only table with appropriate access controls.

#### Scenario: Private config only

- **WHEN** configuration is stored
- **THEN** it resides in `game_logic.config` with RLS blocking client access

#### Scenario: Config integrity

- **WHEN** inserting config rows
- **THEN** keys are unique and values are non-null JSON

#### Scenario: Consistent access pattern

- **WHEN** game logic functions read configuration
- **THEN** they use `game_logic.get_config(key)` helper function

### Requirement: Schema Placement

The system SHALL place tables in appropriate schemas based on access requirements.

#### Scenario: Public schema tables

- **WHEN** a table needs frontend access (direct or via views)
- **THEN** it resides in `public` schema with appropriate RLS

#### Scenario: game_logic schema tables

- **WHEN** a table is internal-only (algorithm, config, logging)
- **THEN** it resides in `game_logic` schema with service_role-only access

#### Scenario: Embeddings placement

- **WHEN** embeddings are stored
- **THEN** they reside in `game_logic.embeddings` (internal, service_role only)

#### Scenario: Geographic regions placement

- **WHEN** geographic regions are stored
- **THEN** they reside in `game_logic.geographic_regions` (internal, service_role only)

### Requirement: Embeddings Storage

The system SHALL store text embeddings in `game_logic` schema with service_role-only access.

#### Scenario: Embedding persistence

- **WHEN** an embedding is stored
- **THEN** it records id, source_text, 384d vector, and timestamps in `game_logic.embeddings`

#### Scenario: Indexing

- **WHEN** querying embeddings by similarity
- **THEN** an HNSW index exists on the embedding column using vector_cosine_ops

#### Scenario: Access control

- **WHEN** accessing embeddings
- **THEN** only SECURITY DEFINER functions or service_role can read/write

### Requirement: Geographic Regions

The system SHALL store geographic regions in `game_logic` schema with service_role-only access.

#### Scenario: Region fields

- **WHEN** a region is stored
- **THEN** it has id, name, level, geometry, and timestamps in `game_logic.geographic_regions`

#### Scenario: Constraints and indexes

- **WHEN** validating regions
- **THEN** level is constrained to allowed values; GIST index exists on geometry

#### Scenario: Access control

- **WHEN** accessing geographic regions
- **THEN** only SECURITY DEFINER functions or service_role can read/write

## ADDED Requirements

### Requirement: No Dead Code

The system SHALL not contain unused tables or functions.

#### Scenario: Table usage verification

- **WHEN** a table exists in the schema
- **THEN** it is actively queried by application code or referenced by foreign keys

#### Scenario: Function usage verification

- **WHEN** a function exists in the schema
- **THEN** it is actively called by application code, triggers, or scheduled jobs
