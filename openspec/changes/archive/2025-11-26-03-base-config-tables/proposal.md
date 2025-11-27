# Change: Add Base Config Tables

## Why

Provide runtime configuration split by visibility so public and private settings are stored in the database.

## What Changes

- Create public.config and game_logic.config tables with key/value pairs
- Define access patterns: public readable, private inaccessible except via privileged functions
- Seed minimal required keys

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/config.sql, supabase/db/game_logic/tables/config.sql
