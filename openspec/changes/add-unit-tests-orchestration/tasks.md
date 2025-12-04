# Tasks: add-unit-tests-orchestration

## 1. Create test file structure

- [ ] 1.1 Create `supabase/tests/test_orchestration.sql`
- [ ] 1.2 Add pgTAP setup (plan, auth context, test mode)
- [ ] 1.3 Create temp tables for test data (traits, places, regions)

## 2. Test `select_best_question`

- [ ] 2.1 Test: Geographic question preferred when split_quality >= threshold (0.7)
- [ ] 2.2 Test: Semantic question chosen when geographic below threshold
- [ ] 2.3 Test: Geographic fallback when no semantic questions available
- [ ] 2.4 Test: No questions available returns empty result
- [ ] 2.5 Test: Already-asked questions are filtered out

## 3. Test `get_geographic_questions`

- [ ] 3.1 Test: Returns regions ranked by split_quality DESC
- [ ] 3.2 Test: Filters out regions already asked about
- [ ] 3.3 Test: Limit parameter works (returns at most N results)
- [ ] 3.4 Test: Empty when no regions have not been asked
- [ ] 3.5 Test: Respects geographic_level (shallowest confirmed)

## 4. Test `get_semantic_questions`

- [ ] 4.1 Test: Returns traits ranked by split_quality DESC
- [ ] 4.2 Test: Filters out traits already asked about
- [ ] 4.3 Test: Limit parameter works (returns at most N results)
- [ ] 4.4 Test: Empty when no traits remain (all asked)
- [ ] 4.5 Test: Tie-breaks by embedding similarity (description vs trait)

## 5. Test `decide_next_turn`

- [ ] 5.1 Test: Chooses GUESS when should_guess() returns true
- [ ] 5.2 Test: Chooses QUESTION when should_guess() returns false
- [ ] 5.3 Test: Chooses GUESS when only 1 candidate remains
- [ ] 5.4 Test: Chooses GIVE_UP when 0 candidates remain
- [ ] 5.5 Test: Detects game-over (exceeded max_turns)
- [ ] 5.6 Test: Uses dynamic threshold based on turn count
- [ ] 5.7 Test: Passes correct turn/candidate count to should_guess

## 6. Test error handling

- [ ] 6.1 Test: Invalid session raises exception
- [ ] 6.2 Test: Null candidates handled gracefully
- [ ] 6.3 Test: Missing config values use defaults

## 7. Verify

- [ ] 7.1 Run `bun run test:db` and verify all tests pass
- [ ] 7.2 Verify no external service calls (LLM, embeddings)
- [ ] 7.3 Confirm test file line count is reasonable (<300 lines)
