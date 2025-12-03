# Change: Add smart confidence thresholds with normalized probabilities

## Why

Current confidence display shows raw similarity scores (0.51, 0.37) that don't sum to 100% and stay unchanged after geographic filtering. This confuses users who expect "58% sure it's Rome" style probabilities. Additionally, the guess threshold is static, but should adapt based on game progress, candidate count, and margin.

## What Changes

### Normalize Confidence to 100%

- Apply softmax normalization after every change (geographic filter or semantic adjustment)
- User sees "58% sure it's Rome" - intuitive probability that sums to 100%
- Algorithm also uses normalized values for decisions

### Dynamic Guess Threshold

- Base threshold interpolates from 0.90 (turn 0) to 0.60 (final turn)
- Bonus adjustments for few candidates (≤3) and high margin (≥25%)
- Additive stacking with floor (0.50) and ceiling (0.95) protection

### New Config Knobs (8 total)

- `confidence.guess_threshold_max` = 0.90
- `confidence.guess_threshold_min` = 0.60
- `confidence.threshold_floor` = 0.50
- `confidence.threshold_ceiling` = 0.95
- `confidence.candidate_low_threshold` = 3
- `confidence.candidate_bonus` = 0.10
- `confidence.margin_high_threshold` = 0.25
- `confidence.margin_bonus` = 0.10

### Remove Old Config

- `confidence.top_prob_threshold` (replaced by dynamic system)
- `confidence.margin_threshold` (folded into margin_bonus)
- `confidence.entropy_threshold` (entropy less intuitive than margin)

## Impact

- Affected specs: `algorithm`
- Affected code: `supabase/db/game_logic/functions/`
- Affected config: `supabase/seeds/00_static_data.sql`
- **User-visible change**: Confidence now shows as percentages summing to 100%
