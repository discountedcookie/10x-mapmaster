# Database Schema Source Files

This directory contains complete database schema definitions organized by function and dependency order.

## Purpose

These files enable a **source-based development workflow** where:

- **Schema changes** are made in source files, not migrations
- **Migrations** are generated automatically from source changes
- **All business logic** lives in the database (database-first architecture)

## File Organization

All files are **idempotent** (safe to run multiple times) and ordered by dependencies:

### 1. `01_extensions.sql` (194 lines)

**PostgreSQL Extensions & Types** - Required extensions, custom types, and schemas

**Extensions**: pgvector, PostGIS, pgcrypto, pg_cron, pg_net, http, pg_graphql, pg_stat_statements, supabase_vault, uuid-ossp

**Custom Types**:

- `game_session_status` - Game lifecycle states
- `question_type` - Geographic vs semantic questions
- `geographic_level` - Continent/region/country hierarchy
- `error_response` - Standardized RPC error format

**Schemas**:

- `public` - Standard public schema
- `game_logic` - Server-only functions and config

### 2. `02_tables.sql` (369 lines)

**Core Database Tables** - All table definitions with constraints and relationships

**Data Tables**:

- `geographic_regions` - Continents and countries with PostGIS geometries
- `embeddings` - Text embeddings with deduplication by hash
- `places` - Geographic locations with traits and embeddings
- `place_traits` - Canonical trait vocabulary
- `place_trait_links` - Many-to-many place-trait relationships with provenance

**Game Tables**:

- `game_sessions` - Game state with trait-based filtering
- `game_answers` - Player answers and question responses
- `question_stats` - Question effectiveness tracking

**Configuration Tables**:

- `public.config` - Client-visible settings (e.g., game.max_turns)
- `game_logic.config` - Server-only algorithm parameters
- `app_settings` - Legacy settings (backward compatibility)

**System Tables**:

- `rate_limit_log` - Rate limiting enforcement and analytics

### 3. `03_rls.sql` (378 lines)

**Row Level Security Policies** - Fine-grained access control for all tables

**Security Model**:

- **Anonymous users**: Can create/play sessions, cannot access persistent data
- **Authenticated users**: Full access to own data, read-only access to reference data
- **Service role**: Full administrative access

**Policy Coverage**: All tables have RLS enabled with appropriate policies

### 4. `04_indexes.sql` (121 lines)

**Database Indexes** - Performance optimization for all query patterns

**Index Types**:

- **HNSW**: Vector similarity search (embeddings, places)
- **GiST**: Geographic queries (PostGIS geometries)
- **B-tree**: Standard lookups and ordering
- **GIN**: Array indexing (traits)

### 5. `05_triggers.sql` (58 lines)

**Database Triggers & Permissions** - Automated workflows and function security

**Triggers**:

- `enrich_place_on_session_complete` - Auto-enrichment on successful games

**Function Permissions**:

- `generate_embedding` - Internal-only (revoked from public/anonymous)

### 6. `06_views.sql` (200+ lines)

**Database Views** - Frontend-friendly data access with built-in security

**Views**:

- `game_session_state` - Complete game state for UI
- `user_stats` - Personal statistics and performance metrics
- `global_stats` - Analytics and leaderboards (service role only)

## Quick Start

### Execute in order:

```bash
psql -f 01_extensions.sql
psql -f 02_tables.sql
psql -f 03_rls.sql
psql -f 04_indexes.sql
psql -f 05_triggers.sql
psql -f 06_views.sql
```

### Development workflow:

```bash
# Make changes to source files
bun run db:rebuild  # Regenerates migration and resets database
bun run db:test     # Runs pgTAP tests
```

## Key Statistics

- **Extensions**: 10
- **Tables**: 11
- **Views**: 3
- **Custom Types**: 4
- **RLS Policies**: 25+
- **Indexes**: 30+
- **Triggers**: 1
- **Total Lines**: 1300+

## Schema Organization

### Public Schema (Client Accessible)

**Reference Data** (read-only for clients):

- `geographic_regions` - Geographic question generation
- `embeddings` - Embedding cache (read-only)
- `places` - Place database with traits
- `place_traits` - Trait vocabulary
- `place_trait_links` - Place-trait relationships

**Game Data** (user-scoped access):

- `game_sessions` - User's game sessions
- `game_answers` - User's game answers

**Configuration** (public visibility):

- `public.config` - Client-visible settings
- `app_settings` - Legacy configuration

**Analytics** (restricted access):

- `user_stats` - Personal statistics (own user only)
- `global_stats` - Global analytics (service role only)

### Game Logic Schema (Server Only)

**Configuration**:

- `game_logic.config` - Algorithm parameters and thresholds

**System**:

- `rate_limit_log` - Rate limiting enforcement

## Configuration System

### Public Config (`public.config`)

Client-visible settings that affect UI behavior:

```sql
-- Example entries
INSERT INTO
  public.config (key, value, description)
VALUES
  (
    'game.max_turns',
    '5',
    'Maximum turns before forced guess'
  ),
  ('ui.theme.default', 'light', 'Default UI theme');
```

### Game Logic Config (`game_logic.config`)

Server-only algorithm parameters from `spec/algorithm.md`:

```sql
-- Scoring parameters
INSERT INTO
  game_logic.config (key, value, description)
VALUES
  (
    'scoring.temperature',
    '0.7',
    'Softmax temperature for probability distribution'
  ),
  (
    'scoring.initial_candidate_threshold',
    '0.3',
    'Minimum similarity to become candidate'
  ),
  (
    'scoring.max_initial_candidates',
    '50',
    'Maximum candidates to consider'
  );

-- Confidence thresholds  
INSERT INTO
  game_logic.config (key, value, description)
VALUES
  (
    'confidence.top_prob_threshold',
    '0.8',
    'Minimum top probability to guess'
  ),
  (
    'confidence.margin_threshold',
    '0.15',
    'Minimum gap between top two candidates'
  ),
  (
    'confidence.entropy_threshold',
    '0.6',
    'Maximum normalized entropy to guess'
  );

-- Trait matching
INSERT INTO
  game_logic.config (key, value, description)
VALUES
  (
    'traits.strong_match_threshold',
    '0.8',
    'Similarity for strong match zone'
  ),
  (
    'traits.partial_match_threshold',
    '0.6',
    'Similarity for partial match zone'
  ),
  (
    'traits.base_weight',
    '0.3',
    'Maximum adjustment magnitude'
  ),
  (
    'traits.beta',
    '2.0',
    'Power-law exponent for match weighting'
  );
```

### App Settings (Legacy)

`app_settings` table maintained for backward compatibility during migration.

## Vector Configuration

All embeddings use **1024 dimensions** (current implementation):

- `embeddings.embedding` - vector(1024) with HNSW index
- Indexed with `vector_cosine_ops` for similarity search
- Deduplicated by SHA256 hash for storage efficiency

## PostGIS Configuration

All geometries use **SRID 4326** (WGS84):

- `geographic_regions.geom` - MultiPolygon for continents/countries
- `places.geom` - Point or Polygon for place boundaries
- GiST indexes for spatial containment queries

## Security Model

### Row Level Security

**Anonymous Users**:

- Can create sessions and play games
- Cannot access other users' data
- Rate limited by IP address

**Authenticated Users**:

- Full access to own game data
- Read access to reference data (places, traits, regions)
- Can view own statistics

**Service Role**:

- Full administrative access
- Can manage configuration and enrichment
- Access to global analytics

### Function Security

**SECURITY DEFINER** functions validate `auth.uid()`:

- All game functions use `auth.uid()` internally
- No user_id parameters (prevents privilege escalation)
- Rate limiting enforced at entry points

## Maintenance Jobs

**Scheduled via pg_cron**:

1. **Daily Maintenance** (`daily-maintenance` - 2 AM UTC):
   - Delete expired sessions (24+ hours inactive)
   - Prune question stats (keep top 450)
   - Clean up old rate limit logs

2. **Rate Limit Cleanup** (`rate-limit-cleanup` - Every 30 minutes):
   - Delete rate limit entries older than 1 hour

## Related Files

- **Functions**: `supabase/db/functions/` - Business logic implementation
- **Tests**: `supabase/tests/` - pgTAP test suite
- **Seeds**: `supabase/seeds/` - Initial data and configuration
- **Migrations**: `supabase/migrations/` - Generated from source files

## Development Workflow

1. **Make changes** to schema source files
2. **Run `bun run db:rebuild`** to regenerate migration
3. **Test with `bun run db:test`** to verify changes
4. **Commit both source files and generated migration**

## See Also

- **QUICK_REFERENCE.md** - Common queries and maintenance tasks
- **spec/algorithm.md** - Algorithm configuration reference
- **supabase/tests/** - Schema validation tests
