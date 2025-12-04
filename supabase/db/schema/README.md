# Database Schema Source Files

This directory contains global schema definitions (extensions, types, triggers, views).

## Purpose

These files enable a **source-based development workflow** where:

- **Schema changes** are made in source files, not migrations
- **Migrations** are generated automatically from source changes
- **All business logic** lives in the database (database-first architecture)

## Overall File Organization

```
supabase/db/
├── schema/                  # Global definitions (this directory)
│   ├── 01_extensions.sql    # Extensions, types, schemas
│   ├── 05_triggers.sql      # Trigger definitions
│   └── 06_views.sql         # View definitions
├── public/tables/           # Public-schema tables (by schema)
│   ├── places.sql
│   ├── embeddings.sql
│   ├── game_sessions.sql
│   └── ...
├── game_logic/tables/       # Game_logic-schema tables (by schema)
│   └── config.sql
└── functions/               # Functions (by domain, not schema)
    ├── game/                # Core game functions
    ├── algorithm/           # Scoring algorithms
    ├── utilities/           # Helper functions
    ├── places/              # Place management
    ├── questions/           # Question generation
    └── maintenance/         # Cleanup jobs
```

**Key distinction:**

- **Tables**: Organized by **schema** (public/ or game_logic/)
- **Functions**: Organized by **domain** (game/, algorithm/, etc.) - schema is specified in SQL
- **Views**: In schema/06_views.sql - schema specified in SQL

## Files in This Directory

### 1. `01_extensions.sql`

**PostgreSQL Extensions & Types** - Required extensions, custom types, and schemas

**Extensions**: pgvector, PostGIS, pgcrypto, pg_cron, pg_net, http, pg_graphql, pg_stat_statements, supabase_vault, uuid-ossp

**Custom Types**:

- `game_session_status` - Game lifecycle states (active, won, ended, needs_submission)
- `question_type` - Geographic vs semantic questions
- `geographic_level` - Continent/region/country hierarchy
- `answer_value` - Answer enum (yes, no, not_sure)
- `error_response` - Standardized RPC error format

**Schemas**:

- `public` - Client-accessible tables and RPC functions
- `game_logic` - Server-only functions and config

### 2. `05_triggers.sql`

**Database Triggers & Permissions** - Automated workflows and function security

**Triggers**:

- `enrich_place_on_session_complete` - Auto-enrichment on successful games
- `on_session_approval_regenerate_traits` - Regenerate traits when session approved

**Function Permissions**:

- `generate_embedding` - Internal-only (revoked from public/anonymous)

### 3. `06_views.sql`

**Database Views** - Frontend-friendly data access with built-in security

**Views**:

- `game_session_state` - Complete game state for UI (derives status from was_correct/next_turn)
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

-- Dynamic confidence thresholds
INSERT INTO
  game_logic.config (key, value, description)
VALUES
  (
    'confidence.guess_threshold_max',
    '0.90',
    'Maximum threshold at turn 0 (conservative)'
  ),
  (
    'confidence.guess_threshold_min',
    '0.60',
    'Minimum threshold at final turn (aggressive)'
  ),
  (
    'confidence.threshold_floor',
    '0.50',
    'Absolute minimum threshold'
  ),
  (
    'confidence.threshold_ceiling',
    '0.95',
    'Absolute maximum threshold'
  ),
  (
    'confidence.candidate_low_threshold',
    '3',
    'Candidate count below which bonus applies'
  ),
  (
    'confidence.candidate_bonus',
    '0.10',
    'Threshold reduction for few candidates'
  ),
  (
    'confidence.margin_high_threshold',
    '0.25',
    'Margin above which bonus applies'
  ),
  (
    'confidence.margin_bonus',
    '0.10',
    'Threshold reduction for high margin'
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

All embeddings use **384 dimensions** (all-MiniLM-L6-v2 model):

- `embeddings.embedding` - vector(384) with HNSW index
- Indexed with `vector_cosine_ops` for similarity search
- Deduplicated by SHA256 hash for storage efficiency

## PostGIS Configuration

All geometries use **SRID 4326** (WGS84):

- `geographic_regions.geom` - MultiPolygon for continents/countries
- `places.geom` - Point or Polygon for place boundaries
- GiST indexes for spatial containment queries

## Security Model

### Auth Personas

The database recognizes three auth personas:

| Persona           | `auth.uid()` | `auth.role()`   | Typical Use Case                            |
| ----------------- | ------------ | --------------- | ------------------------------------------- |
| **Anonymous**     | NULL         | `anon`          | Guest users, first-time visitors            |
| **Authenticated** | UUID (set)   | `authenticated` | Registered users via OAuth/email            |
| **Service Role**  | N/A          | `service_role`  | Admin operations, cron jobs, edge functions |

**Anonymous Users** (`auth.uid() IS NULL`):

- Can create sessions and play games (sessions stored with `user_id = NULL`)
- Cannot access other users' data
- Rate limited per session
- Sessions marked `pending_review = true` require admin approval

**Authenticated Users** (`auth.uid()` is set):

- Full access to own game data (`user_id = auth.uid()`)
- Read access to reference data (places, traits, regions)
- Can view own statistics
- Sessions auto-approved (`pending_review = false`)

**Service Role** (`auth.role() = 'service_role'`):

- Full administrative access (bypasses RLS)
- Can manage configuration and enrichment
- Access to global analytics
- Used by cron jobs and edge functions

### SECURITY DEFINER Guardrails

All `SECURITY DEFINER` functions MUST follow these guardrails:

1. **Auth Check**: Check `auth.uid() IS NOT NULL` at function start when user context required
2. **Search Path**: Set explicit `search_path = public, game_logic, extensions` to prevent schema injection
3. **Ownership Validation**: Verify session/resource ownership before modifications

**Template for SECURITY DEFINER functions**:

```sql
CREATE OR REPLACE FUNCTION public.my_secure_function(p_param text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game_logic, extensions
AS $$
BEGIN
  -- GUARDRAIL 1: Validate authentication
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- GUARDRAIL 2: Validate ownership (for user-scoped resources)
  IF NOT EXISTS (
    SELECT 1 FROM game_sessions
    WHERE id = p_session_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- Business logic here...
END;
$$;
```

**Non-SECURITY DEFINER functions** (SECURITY INVOKER, the default):

- Inherit caller's privileges
- Protected by RLS automatically
- Should still set explicit `search_path` for consistency

### RLS Posture

Tables are classified by access pattern:

| Classification  | RLS Pattern                 | Examples                                       |
| --------------- | --------------------------- | ---------------------------------------------- |
| **User-Owned**  | `auth.uid() = user_id`      | `game_sessions`, `game_answers`                |
| **Public Read** | SELECT allowed for all      | `places`, `place_traits`, `geographic_regions` |
| **Private**     | Blocked except service_role | `game_logic.*` tables                          |

**RLS Policy Templates**:

**User-Owned Table Template** (for tables with `user_id` column):

```sql
-- SELECT: Own data OR anonymous (both NULL) OR service_role
CREATE POLICY "select_own" ON public.my_table FOR
SELECT
  USING (
    (auth.uid () = user_id)
    OR (
      auth.uid () IS NULL
      AND user_id IS NULL
    )
    OR (auth.role () = 'service_role')
  );

-- INSERT: Own data only (prevents inserting as other users)
CREATE POLICY "insert_own" ON public.my_table FOR INSERT
WITH
  CHECK (
    (
      auth.uid () IS NOT NULL
      AND auth.uid () = user_id
    )
    OR (
      auth.uid () IS NULL
      AND user_id IS NULL
    )
    OR (auth.role () = 'service_role')
  );

-- UPDATE/DELETE: Same pattern as SELECT
```

**Public Read-Only Table Template**:

```sql
CREATE POLICY "select_all" ON public.ref_table FOR
SELECT
  USING (true);

-- No INSERT/UPDATE/DELETE policies = write blocked for non-service_role
```

**Private Table Pattern** (in `game_logic` schema):

- No direct RLS needed - schema not exposed to clients
- Access only through SECURITY DEFINER functions
- Grant USAGE on schema to allow function execution

### Function Security

**Public RPC Functions** (`start_game`, `play_turn`, `submit_place`):

- Exposed via Supabase RPC
- Use `auth.uid()` internally for ownership
- No user_id parameters (prevents privilege escalation)
- Rate limiting enforced at entry points
- `submit_place` is SECURITY DEFINER with explicit auth check

**Internal Functions** (in `game_logic` schema):

- Not directly callable by clients
- Called by public RPC functions
- Trust boundary at public function layer

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
