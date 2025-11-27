# Change: Add Question Selection

## Why

Select the most discriminating next question using split quality across geographic and semantic options.

## What Changes

- Compute split_quality for traits and regions
- Prefer geographic when above threshold; tie-break by description similarity for semantic

## Impact

- Affected specs: algorithm
- Affected code: supabase/db/game_logic/functions/algorithm/\* (question selection)
