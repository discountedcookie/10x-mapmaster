## 1. Fix Function

- [ ] 1.1 Replace `nominatim_place_id` with `osm_id` in deduplicate_places.sql
- [ ] 1.2 Remove all `descriptors` column references
- [ ] 1.3 Remove `v_combined_descriptors` variable and related logic
- [ ] 1.4 Keep only `times_encountered` summation for merge stats

## 2. Add Tests

- [ ] 2.1 Create `supabase/tests/test_functions_deduplicate.sql`
- [ ] 2.2 Test: merges places with same osm_id
- [ ] 2.3 Test: merges nearby places with similar names
- [ ] 2.4 Test: sums times_encountered correctly
- [ ] 2.5 Test: updates game_sessions references

## 3. Verify

- [ ] 3.1 Run `bun run db:rebuild` to apply changes
- [ ] 3.2 Run `bun run test:db` to verify tests pass
