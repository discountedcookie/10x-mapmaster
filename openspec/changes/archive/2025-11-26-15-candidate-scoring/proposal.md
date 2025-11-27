# Change: Add Candidate Scoring

## Why

Rank places by semantic similarity to the description using embeddings and temperature-scaled probabilities.

## What Changes

- Implement scoring function using embedding similarity and temperature softmax
- Apply initial candidate capping/thresholds

## Impact

- Affected specs: algorithm
- Affected code: supabase/db/game_logic/functions/algorithm/\* (scoring)
