# Tasks: Game Core

## Phase 1 – RPC Contracts

- [x] 1.1 Implement `start_game` RPC (openspec/specs/game-core/spec.md#game-initialization)
- [x] 1.2 Implement `play_turn` RPC (spec/game-core.md#turn-processing)
- [ ] 1.3 Implement `submit_place` RPC (spec/game-core.md#place-submission)

## Phase 2 – Turn Helpers

- [x] 2.1 Build `record_game_answer` + state update helpers (spec/game-core.md#turn-processing)
- [x] 2.2 Implement `decide_next_turn` using algorithm engine outputs (spec/game-core.md#confidence-based-guessing)
- [x] 2.3 Implement `filter_geographic_candidates` and `filter_semantic_candidates` wrappers (spec/game-core.md#question-selection)

## Phase 3 – Learning Pipeline

- [ ] 3.1 Implement `regenerate_place_traits` trigger + helper (spec/game-core.md#learning-system)
- [ ] 3.2 Auto-approve sessions on account upgrade (spec/game-core.md#learning-system)
- [ ] 3.3 Pending review workflow + triggers (spec/game-core.md#learning-system)

## Phase 4 – Lifecycle & Maintenance

- [ ] 4.1 Implement `needs_submission → ended` flow with place linkage (spec/game-core.md#game-end-conditions)
- [ ] 4.2 Implement abandoned session cleanup via pg_cron (spec/game-core.md#session-cleanup)
- [ ] 4.3 Update stats after each session (spec/game-core.md#game-states)

## Phase 5 – Tests

- [ ] 5.1 pgTAP tests covering start→win flow, give up flow, learning triggers (spec/operations.md#testing-strategy)
