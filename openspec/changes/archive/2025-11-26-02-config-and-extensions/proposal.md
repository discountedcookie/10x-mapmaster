# Change: Add Config and Extensions

## Why

Create core schemas and install required extensions/types so database features (pgvector, PostGIS, pg_cron) and enums are available consistently.

## What Changes

- Create schemas (extensions, public, game_logic) and set search_path patterns
- Install pgvector (384d), PostGIS, pg_cron; define enums/types used across tables
- Document extension schemas and usage

## Impact

- Affected specs: database
- Affected code: supabase/db/schema/01_extensions.sql, schema README
