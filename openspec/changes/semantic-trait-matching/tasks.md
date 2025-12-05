# Tasks: Semantic Trait Matching

## Phase 1: Core Functions

### 1.1 Ordinal Model

- [ ] Create `ordinal_prob(eta, delta_0, delta_1, answer)` — returns P(answer | eta)
- [ ] Create `compute_eta(place_id, trait_id)` — returns η for a place-trait pair
- [ ] Unit tests: probabilities sum to 1, correct ordering (NO < NOT_SURE < YES as η increases)

### 1.2 Embedding-Parameterized Parameters

- [ ] Create `compute_trait_alpha(trait_embedding)` — returns α_q from embedding
- [ ] Create `compute_trait_m(trait_embedding)` — returns m_q from embedding
- [ ] Add config keys: `model.w_alpha`, `model.w_m`, `model.b_alpha`, `model.b_m`
- [ ] Add config keys: `model.delta_0`, `model.delta_1`
- [ ] Initial values: global (α, m) from current boost/penalty logic

### 1.3 Score Updates

- [ ] Modify `adjust_candidates_for_answer` to use ordinal model
- [ ] For each place: `log_score += ln(P(answer | eta))`
- [ ] NOT_SURE contributes likelihood (not zero as before)
- [ ] Unit tests: all three answer types update scores correctly

### 1.4 Information Gain

- [ ] Modify `compute_information_gain` for three outcomes
- [ ] Compute P(YES), P(NOT_SURE), P(NO) aggregated over candidates
- [ ] Expected entropy = weighted sum of conditional entropies
- [ ] IG = H(now) - E[H(after)]
- [ ] Unit tests: IG is non-negative, selects discriminating traits

## Phase 2: Tooling

### 2.1 Algorithm Inspection Views

- [ ] Create view `algorithm_state` — current candidates with scores, probabilities, similarities
- [ ] Create view `trait_evaluation` — traits with their (α_q, m_q) and information gain
- [ ] Create view `turn_impact` — how each turn changed candidate rankings

### 2.2 Game Replay

- [ ] Create table `game_log` — stores per-turn snapshots (session, turn, candidates_json, question, answer)
- [ ] Trigger to log on each `play_turn` call
- [ ] Create function `replay_game(session_id)` — returns turn-by-turn state progression

### 2.3 Algorithm Tuning Skill

- [ ] Create `.opencode/skills/algorithm-tuning/SKILL.md`
- [ ] Document: how to inspect algorithm state
- [ ] Document: how to interpret scores and information gain
- [ ] Document: config knobs and what they do
- [ ] Document: common tuning scenarios

### 2.4 Batch Testing

- [ ] Create `scripts/batch-test-games.ts` — runs N games with known places
- [ ] Input: array of {description, expected_place_osm_id}
- [ ] Output: turns_to_guess, correct, score_progression per game
- [ ] Summary stats: success rate, avg turns, failure cases

## Phase 3: Metric Exploration

### 3.1 Infrastructure

- [ ] Add config key `metric.type` — 'cosine' | 'diagonal' | 'low_rank'
- [ ] Add config key `metric.W_diagonal` — JSON array of weights
- [ ] Add config key `metric.W_matrix` — JSON 2D array (for low-rank)
- [ ] Modify similarity function to dispatch on metric.type

### 3.2 Diagonal W

- [ ] Implement diagonal reweighting: `sim = Σ w_j² · e_i[j] · e_q[j] / norm`
- [ ] Create script to fit W_diagonal from game logs
- [ ] Analyze: which dimensions get upweighted/downweighted?

### 3.3 Low-Rank W (Optional)

- [ ] Implement low-rank projection if diagonal helps
- [ ] Store transformed embeddings or apply at query time
- [ ] Analyze: what geographic structure emerges?

## Phase 4: Tuning

### 4.1 Play and Observe

- [ ] Play games with various descriptions
- [ ] Use algorithm inspection views to understand behavior
- [ ] Note: which cases feel wrong?

### 4.2 Parameter Tuning

- [ ] Adjust δ₀, δ₁ based on NOT_SURE behavior
- [ ] Adjust w_α, w_m based on trait discrimination
- [ ] Adjust metric W if using learned similarity

### 4.3 Iteration

- [ ] Run batch tests after tuning
- [ ] Compare: turns to guess, success rate
- [ ] Repeat until it feels right

## Phase 5: Cleanup

- [ ] Remove old boost_factor/penalty_factor config
- [ ] Remove binary scoring functions
- [ ] Update algorithm spec with final model
- [ ] Update gameplay-sql skill with new queries

---

## Summary

| Phase      | Focus                             | Tasks |
| ---------- | --------------------------------- | ----- |
| 1: Core    | Ordinal model, score updates, IG  | ~12   |
| 2: Tooling | Inspection, replay, batch testing | ~10   |
| 3: Metric  | Learned similarity (optional)     | ~7    |
| 4: Tuning  | Play, observe, adjust             | ~6    |
| 5: Cleanup | Remove old code, update docs      | ~4    |

**Total: ~39 tasks** (down from 80)

Phases 3 and 4 are iterative — do as much or as little as needed.
