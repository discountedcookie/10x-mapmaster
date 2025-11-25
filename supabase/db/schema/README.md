# Database Schema Source Files

This directory contains the complete database schema definitions extracted from migrations into organized, reusable source files.

## Purpose

These files enable a **dev/prod build system** where:

- **Dev mode**: All schema + functions → single migration for rapid iteration
- **Prod mode**: Incremental migrations only for safe deployments

## File Organization

All files are **idempotent** (safe to run multiple times) and ordered by dependencies:

### 1. `01_extensions.sql` (49 lines)

**PostgreSQL Extensions** - All required extensions for the application

### 2. `02_tables.sql` (156 lines)

**Core Database Tables** - Four main tables: places, questions, game_answers, game_sessions

### 3. `03_rls.sql` (62 lines)

**Row Level Security Policies** - RLS policies for all tables with anonymous user support

### 4. `04_indexes.sql` (50 lines)

**Database Indexes** - 23 performance indexes (HNSW, GiST, B-tree)

### 5. `05_triggers.sql` (40 lines)

**Database Triggers** - 4 trigger definitions for place enrichment and session management

## Quick Start

### Execute in order:

```bash
psql -f 01_extensions.sql
psql -f 02_tables.sql
psql -f 03_rls.sql
psql -f 04_indexes.sql
psql -f 05_triggers.sql
```

### Or concatenate for dev mode:

```bash
cat *.sql > ../../../migrations/dev_schema.sql
```

## Key Statistics

- **Extensions**: 10
- **Tables**: 4
- **RLS Policies**: 14
- **Indexes**: 23
- **Triggers**: 4
- **Total Lines**: 357

## Tables Overview

| Table             | Purpose              | Key Columns                                                                        |
| ----------------- | -------------------- | ---------------------------------------------------------------------------------- |
| **places**        | Geographic locations | id, name, embedding (1024-d), geom (PostGIS), pending_review                       |
| **questions**     | Narrowing questions  | id, text, embedding (1024-d), question_type, effectiveness_score                   |
| **game_answers**  | Q&A pairs            | id, session_id, question_id, answer, candidates_after                              |
| **game_sessions** | Game state           | id, user_id, place_id, session_status, current_question_id, pending_guess_place_id |

## Key Features

✅ **Idempotent**: All statements use IF NOT EXISTS / DROP IF EXISTS
✅ **Anonymous Support**: RLS policies support NULL user_id
✅ **Cascade Deletes**: Foreign keys use ON DELETE CASCADE
✅ **Performance**: HNSW indexes for embeddings, GiST for geography
✅ **Documented**: Clear headers, comments, and dependencies

## Vector Configuration

All embeddings use **1024 dimensions**:

- `places.embedding` - vector(1024)
- `questions.embedding` - vector(1024)
- `game_sessions.description_embedding` - vector(1024)
- Indexed with HNSW for fast similarity search
- Cosine distance metric

## PostGIS Configuration

All geometries use **SRID 4326** (WGS84):

- `places.geom` - GEOMETRY(Point, 4326)
- Indexed with GiST for spatial queries

## RLS Policies

- **places**: Public read, service role write, users can delete own
- **questions**: Public read, service role write
- **game_answers**: Users can access own session answers
- **game_sessions**: Users can access own sessions (supports anonymous)

## Trigger Functions

Located in `supabase/db/functions/utilities/`:

1. `approve_pending_session()` - Upserts places from approved sessions
2. `enrich_place_on_approval()` - Enriches approved places
3. `enrich_place_on_session_complete()` - Enriches places from successful guesses
4. `touch_session_last_activity()` - Updates session activity timestamp

## Related Files

- **Migrations**: `supabase/migrations/` - Incremental schema changes
- **Functions**: `supabase/db/functions/` - Business logic functions
- **Tests**: `supabase/tests/` - pgTAP test suite
- **Seeds**: `supabase/seeds/` - Initial data loading

## See Also

- **QUICK_REFERENCE.md** - Common queries, maintenance tasks, troubleshooting
- **supabase/migrations/** - Incremental migration history
