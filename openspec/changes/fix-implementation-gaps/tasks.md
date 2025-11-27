## 1. Database Layer

- [x] 1.1 Verify app_settings has all required seed data
- [x] 1.2 Test start_game RPC via psql - must return session_id
- [x] 1.3 Test get_candidates returns valid JSONB array
- [x] 1.4 Test decide_next_turn populates next_turn correctly
- [x] 1.5 Test play_turn RPC processes answers
- [x] 1.6 Test game_session_state view returns correct data
- [x] 1.7 Fix table name mismatches (traits vs place_traits)
- [x] 1.8 Fix get_question to use select_best_question (per docs)
- [x] 1.9 Test multi-turn game via SQL (verify questions rotate)

## 2. Frontend Layer

- [x] 2.1 Fix start_game response handling (UUID, not array)
- [x] 2.2 Fix play_turn call (enum, not boolean)
- [x] 2.3 Fix submitActualPlace to use submit_place RPC
- [x] 2.4 Fix column name (language_code, not description_language_code)

## 3. End-to-End Verification

- [x] 3.1 Play full game via browser - win scenario (Eiffel Tower guessed correctly)
- [ ] 3.2 Play full game via browser - give-up scenario

## 4. Test Suite

- [ ] 4.1 Fix tests to use correct table names
- [ ] 4.2 Run all database tests and fix failures
