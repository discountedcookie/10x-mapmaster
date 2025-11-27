# Tasks: Add play_turn RPC

- [x] Implement play_turn (SECURITY DEFINER) with hardened search_path
- [x] Rate limit check; ownership enforced via RLS
- [x] Route to handle_question or handle_guess based on next_turn action
- [x] Record answer into game_answers; update candidates via algorithm functions
- [x] Recompute next_turn and status via decide_next_turn
- [x] Exceptions for known errors
