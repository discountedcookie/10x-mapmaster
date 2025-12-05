## 1. Sequential Processing

- [ ] 1.1 Add advisory lock acquisition at start of `update_place_traits` using `pg_advisory_xact_lock(hashtext(place_id::text))`
- [ ] 1.2 Lock is automatically released at transaction end (no explicit unlock needed)
- [ ] 1.3 Test: Concurrent calls for same place execute sequentially

## 2. Deduplication Logic

- [ ] 2.1 Create `is_duplicate_trait(place_id, new_embedding_id, threshold)` function
- [ ] 2.2 Implement similarity check using `<#>` operator on trait embeddings
- [ ] 2.3 Add config key `traits.dedup_similarity_threshold` (default 0.92)

## 3. Update Place Traits Function

- [ ] 3.1 Remove `DELETE FROM place_traits` line (currently line 190)
- [ ] 3.2 Add deduplication check before inserting each new trait
- [ ] 3.3 Skip insertion if duplicate found, log to NOTICE

## 4. Tests

- [ ] 4.1 Test: Existing traits are preserved after update_place_traits runs
- [ ] 4.2 Test: New unique traits are added alongside existing ones
- [ ] 4.3 Test: Duplicate traits (high similarity) are not added
- [ ] 4.4 Test: LLM failure does not delete existing traits
- [ ] 4.5 Test: Sequential execution for same place_id
