# Change: Add Trait Matching

## Why

Adjust candidate scores based on answers to semantic trait questions using trait embeddings and configured weights.

## What Changes

- Compute match_strength between place and trait embeddings
- Apply strong/partial thresholds and power-law weighting for yes/no/not_sure answers

## Impact

- Affected specs: algorithm
- Affected code: supabase/db/game_logic/functions/algorithm/\* (trait matching)
