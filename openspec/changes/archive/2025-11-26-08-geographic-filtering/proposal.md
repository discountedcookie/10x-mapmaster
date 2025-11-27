# Change: Add Geographic Filtering

## Why

Enable spatial candidate filtering using regions for geographic questions.

## What Changes

- Implement functions to filter candidates by geographic region using PostGIS
- Provide helpers for inclusion/exclusion logic

## Impact

- Affected specs: algorithm
- Affected code: supabase/db/game_logic/functions/algorithm/\* (geo filtering)
