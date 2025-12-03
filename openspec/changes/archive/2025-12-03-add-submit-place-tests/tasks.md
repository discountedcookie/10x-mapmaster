## 1. Spec Clarification

- [x] 1.1 Extend `openspec/specs/game-core/spec.md` with explicit `submit_place` requirements, including success, invalid session state, invalid `osm_id`, and rate limiting.
- [x] 1.2 Extend `openspec/specs/database/spec.md` to describe the `submit_place` functionʼs inputs, outputs, side effects, and constraints.

## 2. Test Design

- [x] 2.1 Define minimal fixture setup to create a session in `needs_submission` state with a candidate place.
- [x] 2.2 Identify at least 3–5 core scenarios to test:
  - Successful submission for a `needs_submission` session.
  - Session not in `needs_submission` state.
  - Session not owned by the current user.
  - Invalid or missing `osm_id`.
  - Rate limit exceeded behavior.

## 3. Test Implementation

- [x] 3.1 Create `supabase/tests/test_submit_place.sql` using pgTAP, following patterns from existing test files.
- [x] 3.2 Implement the defined scenarios with clear assertions on return values and side effects.

## 4. Verification

- [x] 4.1 Run `supabase test db --file supabase/tests/test_submit_place.sql`.
- [x] 4.2 Update specs or tests if behavior does not match expectations, then re-run tests.
