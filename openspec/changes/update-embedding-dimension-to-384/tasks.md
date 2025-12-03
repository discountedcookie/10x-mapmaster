## 1. Spec Updates

- [ ] 1.1 Update `openspec/specs/database/spec.md` to state that all embeddings are 384-dimensional.
- [ ] 1.2 Update `openspec/specs/algorithm/spec.md` if it refers to vector dimension counts or index assumptions.
- [ ] 1.3 Update `openspec/specs/edge-functions/spec.md` to describe the embedding model and expected vector size.

## 2. Documentation

- [ ] 2.1 Update `supabase/db/schema/QUICK_REFERENCE.md` to replace 1024d references with 384d, including table overviews and the vector configuration section.
- [ ] 2.2 Search `docs/architecture` for any mention of 1024d and update to 384d where appropriate.

## 3. Sanity Checks

- [ ] 3.1 Run `rg "1024"` across the repo to ensure no stale references remain.
- [ ] 3.2 Verify that `supabase/db/public/tables/embeddings.sql` and `supabase/functions/generate-embedding/index.ts` both use 384 dimensions and match the documented spec.
