# Tasks: Algorithm Engine

## Phase 1 – Scoring Foundations

- [x] 1.1 Implement similarity helpers + candidate selection limits (openspec/specs/algorithm/spec.md#initial-candidate-scoring)
- [x] 1.2 Convert scores to probabilities via temperature softmax (spec/algorithm.md#probability-distribution)
- [x] 1.3 Seed config keys for scoring/temperature thresholds (spec/algorithm.md#configuration-parameters)

## Phase 2 – Confidence Metrics

- [x] 2.1 Implement top_prob, margin, normalized_entropy calculations (spec/algorithm.md#confidence-decision-metrics)
- [x] 2.2 Implement decision rule function returning GUESS vs ASK (spec/algorithm.md#guess-decision-rule)

## Phase 3 – Trait Matching

- [x] 3.1 Implement match strength + zones (strong/partial/weak) (spec/algorithm.md#trait-match-scoring)
- [x] 3.2 Implement score adjustments with power-law scaling (spec/algorithm.md#score-adjustment)

## Phase 4 – Question Selection

- [x] 4.1 Implement split quality calculation for semantic traits (spec/algorithm.md#question-split-quality)
- [x] 4.2 Implement geographic vs semantic decision logic (spec/algorithm.md#geographic-vs-semantic-questions)
- [x] 4.3 Implement PostGIS filtering helpers for YES/NO answers (spec/algorithm.md#spatial-filtering)

## Phase 5 – Tests & Docs

- [ ] 5.1 pgTAP tests for scoring + confidence metrics (spec/operations.md#testing-strategy)
- [ ] 5.2 Document tuning knobs in `supabase/db/schema/QUICK_REFERENCE.md`
