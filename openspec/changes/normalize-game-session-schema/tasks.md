## 1. Database Schema Changes

- [ ] 1.1 Create `game_turn` table
  - session_id (PK, FK to game_sessions ON DELETE CASCADE)
  - action (turn_action enum: 'question', 'guess')
  - question_text, question_type, trait_id, geographic_region_id
  - guess_place_id, guess_place_name
  - created_at (timestamptz default now())
  - CHECK constraint: question fields valid when action='question'
  - CHECK constraint: guess fields valid when action='guess'
- [ ] 1.2 Create `game_session_candidates` table
  - (session_id, place_id) composite PK
  - session_id FK to game_sessions ON DELETE CASCADE
  - place_id FK to places
  - probability (double precision NOT NULL)
  - description_similarity, affirmed_trait_similarity, denied_trait_similarity, geographic_distance
  - Indexes: (session_id), (session_id, probability DESC)
- [ ] 1.3 Create RLS policies for new tables
  - game_turn: SELECT/INSERT/UPDATE/DELETE where session.user_id = auth.uid()
  - game_session_candidates: SELECT/INSERT/UPDATE/DELETE where session.user_id = auth.uid()
- [ ] 1.4 Create `get_session_candidates(p_session_id uuid)` function
  - RETURNS TABLE(id, name, lat, lng, probability, description_similarity)
  - SECURITY DEFINER with hardened search_path
  - Validates session ownership
  - Joins candidates with places, orders by probability DESC
- [ ] 1.5 Rewrite `game_session_state` view
  - Flat typed columns (no JSONB output)
  - LEFT JOIN game_turn for action/question/guess fields
  - LEFT JOIN places for final place details
  - Computed status from was_correct, game_turn existence, place_id
- [ ] 1.6 Drop `next_turn` column from `game_sessions`
  - Migration drops column (no data migration needed for dev)

## 2. Game Logic Function Updates

- [ ] 2.1 Update `start_game`
  - Insert candidates into game_session_candidates (not JSONB)
  - Insert first turn into game_turn (not next_turn JSONB)
  - Change return type to TABLE(...) matching game_session_state
- [ ] 2.2 Update `play_turn`
  - Read current turn from game_turn table
  - Change return type to TABLE(...) matching game_session_state
  - Return state via SELECT from game_session_state after mutation
- [ ] 2.3 Update `submit_place`
  - Delete game_turn row when game ends
  - Change return type to TABLE(...) matching game_session_state
- [ ] 2.4 Update `get_candidates`
  - Query game_session_candidates joined with places
  - Return typed result set (not JSONB)
- [ ] 2.5 Update `decide_next_turn`
  - INSERT or UPDATE game_turn table (not next_turn JSONB)
  - On game end: DELETE from game_turn
- [ ] 2.6 Update `handle_question`
  - Read turn state from game_turn table
  - Call decide_next_turn which updates game_turn
- [ ] 2.7 Update `handle_guess`
  - Read turn state from game_turn table
  - On correct: DELETE game_turn, UPDATE game_sessions.was_correct
  - On wrong: DELETE candidate row, call decide_next_turn
- [ ] 2.8 Update `filter_candidates_for_geography`
  - Change to UPDATE/DELETE on game_session_candidates table
  - Input: session_id, region_id, answer
  - No return value (void), operates on table directly
- [ ] 2.9 Update `adjust_candidates_for_answer`
  - Change to UPDATE on game_session_candidates table
  - Input: session_id, trait_id, answer
  - No return value (void), operates on table directly
- [ ] 2.10 Update `apply_softmax_to_candidates`
  - Change to UPDATE on game_session_candidates table
  - Input: session_id, temperature
  - No return value (void), operates on table directly
- [ ] 2.11 Update `record_game_answer`
  - Keep candidates_snapshot parameter (JSONB for historical audit)
  - Build snapshot by querying game_session_candidates instead of receiving JSONB
  - Historical snapshot in game_answers is acceptable (not frontend-facing)
- [ ] 2.12 Remove or deprecate JSONB builder functions
  - `build_guess_turn` - no longer needed (INSERT into game_turn directly)
  - `build_question_turn` - no longer needed (INSERT into game_turn directly)
- [ ] 2.13 Update `global_stats` view
  - Change status calculation to use game_turn table existence instead of next_turn JSONB

## 3. Frontend Updates

- [ ] 3.1 Regenerate Supabase types
  - Run `bun run supabase:types`
  - Verify types for: game_turn, game_session_candidates, game_session_state view, get_session_candidates function
- [ ] 3.2 Update `src/lib/api/index.ts`
  - playTurn: return typed session state (not void)
  - startGame: return typed session state (not just session_id)
  - submitPlace: return typed session state (not void)
  - Add getSessionCandidates(sessionId) calling RPC
  - Remove getGameState (or keep for refresh, but prefer view query)
- [ ] 3.3 Update `src/stores/gameSession.ts`
  - Separate refs: session (game state) and candidates (array)
  - Use Supabase-generated types for both
  - After playTurn: update session from return, then fetch candidates
  - After startGame: update session from return, then fetch candidates
  - Remove all manual type definitions
- [ ] 3.4 Update `src/composables/game/useGameMap.ts`
  - Remove `as unknown as` cast
  - Read candidates from store's typed candidates ref
- [ ] 3.5 Update `src/components/game/states/GameActive.vue`
  - Remove session cast and QuestionJson/GuessJson interfaces
  - Read session.question_text, session.guess_place_name directly

## 4. Database Tests

- [ ] 4.1 Add test_tables_game_turn.sql
  - Test table constraints (action-dependent fields)
  - Test RLS policies
  - Test cascade delete from game_sessions
- [ ] 4.2 Add test_tables_game_session_candidates.sql
  - Test table constraints
  - Test RLS policies
  - Test cascade delete from game_sessions
- [ ] 4.3 Add test_functions_get_session_candidates.sql
  - Test returns correct data
  - Test ownership validation
  - Test ordering by probability
- [ ] 4.4 Update test_game_flow.sql
  - Update to use new table structure
  - Verify candidates in table after each turn
  - Verify game_turn updates correctly
- [ ] 4.5 Update test_sessions.sql
  - Remove tests for next_turn JSONB
  - Add tests for game_turn table behavior

## 5. Verify

- [ ] 5.1 Run `supabase db reset` - verify migration applies cleanly
- [ ] 5.2 Run `bun run test:db` - all database tests pass
- [ ] 5.3 Run `bun run supabase:types` - types generate without errors
- [ ] 5.4 Run `bun run type-check` - TypeScript compiles without errors
- [ ] 5.5 Run `bun run test` - frontend tests pass
- [ ] 5.6 Manual SQL gameplay test via psql
- [ ] 5.7 Manual browser gameplay test
