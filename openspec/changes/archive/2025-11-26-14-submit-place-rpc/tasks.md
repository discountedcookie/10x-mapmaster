# Tasks: Add submit_place RPC

- [x] Implement submit_place (SECURITY DEFINER) with hardened search_path and auth.uid() check
- [x] Enforce ownership/auth; rate limit check
- [x] Validate session in needs_submission state
- [x] Call place enrichment edge function; create/update place with pending_review rules
- [x] Link session to place, set was_correct = FALSE
- [x] If auto-approved, trigger regenerate_place_traits
- [x] Exception handling for errors
