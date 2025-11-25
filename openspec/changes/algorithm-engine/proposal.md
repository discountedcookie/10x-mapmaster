# Change: Algorithm Engine

## Why

The heart of the game is the candidate scoring, confidence decision, trait matching, and question selection logic. We need to codify the mathematical rules from `spec/algorithm.md` inside PostgreSQL so that game turns are deterministic and testable.

## Scope

- Candidate scoring (pgvector similarity + softmax probabilities)
- Confidence decision metrics (top_prob, margin, entropy)
- Trait match scoring + power-law adjustments
- Question split quality + selection (semantic and geographic)
- Spatial filtering helpers
- Configuration keys that drive the algorithms

## Impact

- Enables `start_game` and `play_turn` to make consistent choices
- Unlocks frontend candidate/confidence UI and map visualizations
- Provides tuning levers via `game_logic.config`

## Success Criteria

- SQL functions in `supabase/db/functions/game` + `/utilities` implement all formulas from spec
- pgTAP tests cover scoring, question selection, and decision edges
- Config keys documented with defaults in seeds
