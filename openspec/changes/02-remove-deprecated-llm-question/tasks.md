## 1. Remove Dead Code

- [x] 1.1 Delete `supabase/db/game_logic/functions/questions/get_llm_question.sql`
- [x] 1.2 Remove the `llm_prompt` config from `supabase/seeds/00_static_data.sql` (the selection-focused prompt)
- [x] 1.3 Search for any references to `get_llm_question` and remove them (also removed get_active_prompt)

## 2. Update Build

- [ ] 2.1 Run `bun run db:rebuild` to regenerate migration
- [ ] 2.2 Verify build succeeds without the removed function

## 3. Testing

- [ ] 3.1 Run `supabase test db` to ensure no test depends on removed function
- [ ] 3.2 Verify game still works end-to-end
