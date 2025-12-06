## 1. Add Foreign Key

- [x] 1.1 Add FK constraint to `game_sessions.user_id` referencing `auth.users.id`
- [x] 1.2 Use `ON DELETE SET NULL` (adjusted requirement) to preserve sessions for analytics
- [x] 1.3 Add comment explaining the design decision (sessions preserved for analytics)

## 2. Handle Existing Data

- [x] 2.1 Check for orphaned sessions (user_id not in auth.users)
- [x] 2.2 Set orphaned sessions user_id to NULL before adding constraint
- [x] 2.3 Cleanup applied: 1 orphaned record found and cleaned

## 3. Verify

- [x] 3.1 Run `bun run db:rebuild` to apply changes
- [x] 3.2 Test that invalid user_id is rejected on insert (PASS - FK constraint enforced)
- [x] 3.3 Test that constraint exists in schema (PASS - constraint 'game_sessions_user_id_fkey' verified)
