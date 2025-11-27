# Tasks: Add start_game RPC

- [x] Implement start_game (SECURITY DEFINER) with hardened search_path
- [x] Call rate limiting (check_rate_limit) before work
- [x] Generate embedding for description; create game_session row with embedding_id
- [x] Seed initial candidates via get_candidates; set next_turn via decide_next_turn
- [x] Return session_id on success, exceptions on failure
- [x] Rely on RLS for ownership
