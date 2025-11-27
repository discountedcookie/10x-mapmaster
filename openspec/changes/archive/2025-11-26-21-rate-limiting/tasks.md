# Tasks: Add Rate Limiting

- [x] Create rate_limit_log table with user_id, action, created_at
- [x] Indexes on user_id, action, created_at
- [x] RLS: enable/force; service_role manage only
- [x] Implement check_rate_limit function with configurable limits
- [x] Default limits for start_game, play_turn, submit_place
