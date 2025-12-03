# Tasks: add-smart-confidence-thresholds

## 1. Update Configuration

- [ ] 1.1 Add new config keys to `supabase/seeds/00_static_data.sql`:
  - `confidence.guess_threshold_max` = 0.90
  - `confidence.guess_threshold_min` = 0.60
  - `confidence.threshold_floor` = 0.50
  - `confidence.threshold_ceiling` = 0.95
  - `confidence.candidate_low_threshold` = 3
  - `confidence.candidate_bonus` = 0.10
  - `confidence.margin_high_threshold` = 0.25
  - `confidence.margin_bonus` = 0.10
- [ ] 1.2 Remove old config keys from seed:
  - `confidence.top_prob_threshold`
  - `confidence.margin_threshold`
  - `confidence.entropy_threshold`

## 2. Create Dynamic Threshold Function

- [ ] 2.1 Create `supabase/db/game_logic/functions/algorithm/calculate_dynamic_threshold.sql`:
  - Input: current_turn INT, max_turns INT, candidate_count INT, margin FLOAT
  - Read all config knobs via get_config_float()
  - Calculate: base = lerp(turn/max_turns, threshold_max, threshold_min)
  - Apply candidate_bonus if count <= candidate_low_threshold
  - Apply margin_bonus if margin >= margin_high_threshold
  - Clamp between floor and ceiling
  - Return: threshold FLOAT

## 3. Update should_guess Function

- [ ] 3.1 Modify `supabase/db/game_logic/functions/algorithm/should_guess.sql`:
  - Add parameters: p_current_turn INT, p_max_turns INT, p_candidate_count INT
  - Call calculate_dynamic_threshold() instead of reading static threshold
  - Compare top_prob against dynamic threshold
  - Remove entropy check (no longer used)

## 4. Normalize After Geographic Filter

- [ ] 4.1 Modify `supabase/db/game_logic/functions/handle_question.sql`:
  - After filter_candidates_for_geography(), call apply_softmax_to_candidates()
  - Ensure candidates are normalized before storing in next_turn

## 5. Normalize After Semantic Adjustment

- [ ] 5.1 Verify `supabase/db/game_logic/functions/handle_question.sql`:
  - Already calls apply_softmax_to_candidates() after adjust_candidates_for_answer()
  - Confirm this is working correctly with normalized inputs

## 6. Update decide_next_turn

- [ ] 6.1 Modify `supabase/db/game_logic/functions/decide_next_turn.sql`:
  - Pass current turn count and candidate count to should_guess()
  - Get current turn from counting game_answers for session
  - Get max_turns from get_max_turns()

## 7. Update Tests

- [ ] 7.1 Update `supabase/tests/test_algorithm_functions.sql`:
  - Update should_guess tests to include turn/candidate parameters
  - Add tests for calculate_dynamic_threshold()
  - Test threshold at turn 0 vs final turn
  - Test candidate count bonus
  - Test margin bonus
  - Test additive stacking
  - Test floor/ceiling clamping
- [ ] 7.2 Update `supabase/tests/test_settings_control_behavior.sql`:
  - Update any tests referencing old config keys

## 8. Rebuild and Verify

- [ ] 8.1 Run `bun run db:rebuild` to regenerate migration
- [ ] 8.2 Run `bun run test:db` to verify all tests pass
- [ ] 8.3 Test via SQL gameplay: verify confidence sums to 100% after each turn
- [ ] 8.4 Test via SQL gameplay: verify dynamic threshold affects guess timing
