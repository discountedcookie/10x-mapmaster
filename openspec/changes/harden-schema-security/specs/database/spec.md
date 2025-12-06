## MODIFIED Requirements

### Requirement: Schemas and Extensions

The system SHALL define required schemas and install core extensions and types for the database.

#### Scenario: Schema structure

- **WHEN** deploying the database
- **THEN** schemas `extensions`, `public`, `private`, and `api` exist
- **AND** `public` contains only types and enums (no tables)
- **AND** `private` contains all tables and internal functions
- **AND** `api` contains only views and public-facing RPCs

#### Scenario: Schema exposure

- **WHEN** PostgREST serves the Data API
- **THEN** only `api` schema is exposed to clients
- **AND** `public` and `private` are NOT in the exposed schemas list

#### Scenario: Extensions installed

- **WHEN** extensions are provisioned
- **THEN** pgvector (384d), PostGIS, pgmq, and pg_cron are installed in the extensions schema and available

#### Scenario: Types and enums

- **WHEN** shared types are needed
- **THEN** enums (e.g., status, answer_value) and any composite types are defined in `public` schema for global access

### Requirement: API Schema Design

The system SHALL expose a controlled API surface via the `api` schema.

#### Scenario: API views

- **WHEN** frontend needs to read game data
- **THEN** it queries views in `api` schema: `game_session_state`, `places_with_geometry`, `user_stats`, `global_stats`
- **AND** views use `security_invoker = on` where possible, or document why not

#### Scenario: API functions

- **WHEN** frontend needs to perform game actions
- **THEN** it calls RPCs in `api` schema: `start_game()`, `play_turn()`, `submit_place()`
- **AND** functions are SECURITY DEFINER with explicit auth checks

#### Scenario: No direct table access

- **WHEN** a client attempts to query `private.*` tables
- **THEN** the request fails because `private` is not exposed via PostgREST

### Requirement: Private Schema Permissions

The system SHALL restrict access to the `private` schema tables.

#### Scenario: Client isolation

- **WHEN** anon or authenticated roles attempt to access `private` schema
- **THEN** they have no USAGE grant on the schema
- **AND** they have no SELECT/INSERT/UPDATE/DELETE on any tables

#### Scenario: Service role access

- **WHEN** service_role accesses `private` schema
- **THEN** it has full USAGE and ALL privileges on tables

#### Scenario: Function access

- **WHEN** SECURITY DEFINER functions in `api` schema need to access private tables
- **THEN** they execute as `postgres` owner with full access to `private` schema

### Requirement: API Schema Permissions

The system SHALL grant minimal permissions on the `api` schema.

#### Scenario: View permissions

- **WHEN** clients query `api` views
- **THEN** authenticated users have SELECT on all views
- **AND** anon users have SELECT only on `places_with_geometry`
- **AND** no users have INSERT/UPDATE/DELETE on views

#### Scenario: Function permissions

- **WHEN** clients call `api` RPCs
- **THEN** authenticated users have EXECUTE on `start_game`, `play_turn`, `submit_place`
- **AND** anon users have no EXECUTE on game functions

#### Scenario: Schema usage

- **WHEN** clients access the `api` schema
- **THEN** anon and authenticated have USAGE grant on `api` schema

### Requirement: RLS on Private Tables

The system SHALL enable RLS on all private tables as defense-in-depth.

#### Scenario: RLS enabled

- **WHEN** private tables are created
- **THEN** RLS is enabled on all tables
- **AND** rls_forced is TRUE on security-sensitive tables (config, rate_limit_log, game_sessions, game_answers)

#### Scenario: Service role bypass

- **WHEN** service_role queries private tables
- **THEN** it bypasses RLS to perform maintenance operations

#### Scenario: No client policies needed

- **WHEN** private tables have RLS enabled
- **THEN** no permissive policies for anon/authenticated are created
- **AND** only service_role policies exist

## MODIFIED Requirements

### Requirement: Configuration Tables

The system SHALL store configuration in a private schema with service-role-only access.

#### Scenario: Config table location

- **WHEN** algorithm parameters are stored
- **THEN** they reside in `private.config` (not `game_logic.config`)

#### Scenario: Config access

- **WHEN** accessing `private.config`
- **THEN** only SECURITY DEFINER functions or service_role can read/write
- **AND** clients cannot access via PostgREST because `private` is not exposed

#### Scenario: Config integrity

- **WHEN** inserting config rows
- **THEN** keys are unique and values are non-null JSON

### Requirement: Embeddings Storage

The system SHALL store text embeddings in the private schema with restricted access.

#### Scenario: Embedding location

- **WHEN** an embedding is stored
- **THEN** it is stored in `private.embeddings` table

#### Scenario: Embedding access

- **WHEN** accessing embeddings
- **THEN** only SECURITY DEFINER functions or service_role can read/write
- **AND** RLS with service_role-only policy is enforced

### Requirement: Game Sessions Storage

The system SHALL store game sessions in the private schema, accessed only via API views.

#### Scenario: Session location

- **WHEN** a session is stored
- **THEN** it is stored in `private.game_sessions` table

#### Scenario: Session access

- **WHEN** users need session data
- **THEN** they query `api.game_session_state` view
- **AND** direct table access is blocked

### Requirement: Server-Only Algorithm Configuration

The system SHALL store algorithm configuration in the private schema inaccessible to clients.

#### Scenario: Config table isolation

- **WHEN** algorithm parameters are stored
- **THEN** they reside in `private.config` with RLS blocking client access
- **AND** the schema is not exposed via PostgREST

#### Scenario: Consistent access pattern

- **WHEN** game logic functions read configuration
- **THEN** they use `private.get_config(key)` helper function (renamed from `game_logic.get_config`)
