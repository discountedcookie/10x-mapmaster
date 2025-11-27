# Change: Add Geographic Regions

## Why

Provide geographic regions with geometry and level metadata to support geographic questioning and filtering.

## What Changes

- Create geographic_regions table with name, level, geometry
- Add constraints and GIST index
- Define read-open posture

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/geographic_regions.sql
