# Tasks: Add Session RLS

- [x] Enable and force RLS on game_sessions and game_answers
- [x] Policies: select/insert/update/delete restricted to rows where session.user_id = auth.uid() OR (session.user_id IS NULL AND auth.uid() IS NULL) OR service_role
- [x] Answers inherit access via session_id subquery
- [x] Service_role manage-all policy for maintenance
- [x] RLS tests in test_rls_policies.sql
