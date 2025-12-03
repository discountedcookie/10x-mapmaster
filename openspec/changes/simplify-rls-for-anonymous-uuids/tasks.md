## 1. Spec and Documentation Alignment

- [x] 1.1 Update `openspec/specs/database/spec.md` to clearly document that Supabase anonymous and registered users both have UUID `auth.uid()` values.
- [x] 1.2 Update `supabase/db/schema/QUICK_REFERENCE.md` to remove references to supporting `NULL` user IDs in RLS.

## 2. RLS Audit

- [x] 2.1 Review `supabase/db/public/tables/game_sessions.sql` RLS policies for any implicit `user_id IS NULL` assumptions.
- [x] 2.2 Review `supabase/db/public/tables/game_answers.sql` policies and their subqueries against `game_sessions`.
- [x] 2.3 Search for other RLS policies/views that mention `user_id IS NULL` or anonymous patterns.

## 3. RLS Simplification

- [x] 3.1 Adjust `game_session_state` view and any other views using inline ownership checks to align with UUID-based ownership and avoid "null user" branches.
- [x] 3.2 Simplify or remove any dead code paths in policies that were only for `user_id IS NULL`.

## 4. Tests

- [x] 4.1 Add or update pgTAP tests in `supabase/tests/test_rls_policies.sql` to assert behavior for anonymous UUID users and registered users.
- [x] 4.2 Run `supabase test db --file supabase/tests/test_rls_policies.sql` and ensure all tests pass.
