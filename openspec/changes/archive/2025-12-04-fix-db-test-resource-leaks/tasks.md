## 1. Diagnose Warnings

- [x] 1.1 Re-run `supabase test db` and capture all `TupleDesc` warning locations.
- [x] 1.2 For each warning, locate the exact statement or function call in the relevant test file.

## 2. Refactor Problematic Statements

- [x] 2.1 Replace `SELECT` calls with `PERFORM` when the result is not used.
- [x] 2.2 Ensure all set-returning functions are fully consumed or assigned, rather than partially selected.
- [x] 2.3 Avoid patterns that open a cursor-like context without consuming or closing it.

**Fix applied:** In `select_best_question.sql`, changed `SELECT *` to select specific columns when calling `get_geographic_questions` and `get_semantic_questions` SRFs.

## 3. Verification

- [x] 3.1 Re-run `supabase test db` and confirm that all TupleDesc warnings have been eliminated.
- [x] 3.2 If necessary, add comments in the test files explaining the chosen patterns to avoid reintroducing leaks.

**Note:** Also fixed stale `should_guess` function tests that had incorrect parameter signatures.
