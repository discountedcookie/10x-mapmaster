# Tasks: fix-learning-trigger-errors

## 1. Fix Trigger Definition

- [x] 1.1 Update `enrich_place_on_session_complete_trigger` in `triggers.sql` to fire on `AFTER INSERT OR UPDATE`
- [x] 1.2 Add WHEN clause to trigger to only fire when `was_correct = TRUE` (prevent firing on every insert)

## 2. Fix Silent Errors in enqueue_trait_extraction

- [x] 2.1 Change `RAISE WARNING` to `RAISE EXCEPTION` for missing `supabase_url` config (line ~48)
- [x] 2.2 Change `RAISE WARNING` to `RAISE EXCEPTION` for missing `service_role_key` config (line ~61)
- [x] 2.3 Change `RAISE WARNING` to `RAISE EXCEPTION` in the outer exception handler (line ~91)

## 3. Fix Silent Errors in update_place_traits

- [x] 3.1 Change `RAISE WARNING` to `RAISE EXCEPTION` for failed LLM trait parsing (line ~198)
- [x] 3.2 Change `RAISE WARNING` to `RAISE EXCEPTION` for no traits extracted (line ~256)
- [x] 3.3 Change `RAISE WARNING` to `RAISE EXCEPTION` in outer exception handler (line ~261)
- [x] 3.4 Keep `RAISE WARNING` for Nominatim fetch failure (line ~78) - this is acceptable graceful degradation

## 4. Testing

- [x] 4.1 Run existing database tests to verify no regressions
- [x] 4.2 Test that INSERT with was_correct=TRUE triggers learning
- [x] 4.3 Test that config errors now raise exceptions instead of warnings
- [x] 4.4 Run `bun run db:rebuild` to apply changes
