## 1. Add Foreign Key

- [ ] 1.1 Add FK constraint to `game_sessions.user_id` referencing `auth.users.id`
- [ ] 1.2 Use `ON DELETE CASCADE` for automatic cleanup
- [ ] 1.3 Add comment explaining the constraint

## 2. Handle Existing Data

- [ ] 2.1 Check for orphaned sessions (user_id not in auth.users)
- [ ] 2.2 Delete any orphaned sessions before adding constraint
- [ ] 2.3 Add cleanup query to migration if needed

## 3. Verify

- [ ] 3.1 Run `bun run db:rebuild` to apply changes
- [ ] 3.2 Test that user deletion cascades to sessions
- [ ] 3.3 Test that invalid user_id is rejected on insert
