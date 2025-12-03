## 1. Diagnose Warnings

- [ ] 1.1 Re-run `supabase test db` and capture all `TupleDesc` warning locations.
- [ ] 1.2 For each warning, locate the exact statement or function call in the relevant test file.

## 2. Refactor Problematic Statements

- [ ] 2.1 Replace `SELECT` calls with `PERFORM` when the result is not used.
- [ ] 2.2 Ensure all set-returning functions are fully consumed or assigned, rather than partially selected.
- [ ] 2.3 Avoid patterns that open a cursor-like context without consuming or closing it.

## 3. Verification

- [ ] 3.1 Re-run `supabase test db` and confirm that all TupleDesc warnings have been eliminated.
- [ ] 3.2 If necessary, add comments in the test files explaining the chosen patterns to avoid reintroducing leaks.
