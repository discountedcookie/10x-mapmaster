# Change: Add Confidence Decision

## Why

Determine when to guess versus ask based on confidence metrics derived from probabilities.

## What Changes

- Compute top_prob, margin, normalized_entropy
- Apply guess/ask decision thresholds from config

## Impact

- Affected specs: algorithm
- Affected code: supabase/db/game_logic/functions/algorithm/\* (confidence)
