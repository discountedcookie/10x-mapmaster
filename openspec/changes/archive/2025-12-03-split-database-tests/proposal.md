# Change: Split Database Tests by Domain

## Why

Current pgTAP test files mix unrelated concerns (e.g., `test_rls_policies.sql` covers 5 different tables, `test_schema_validation.sql` checks all tables together). This makes it hard to understand what's being tested and difficult to verify coverage completeness per domain.

## What Changes

- Reorganize 6 test files (87 tests) into ~16 focused domain-based files
- Use naming convention `test_{category}_{domain}.sql` to mirror `supabase/db/` structure
- Each domain file contains its own schema checks, RLS tests, and behavior tests
- Delete original test files after migration

## Impact

- Affected specs: `database` (add testing organization conventions)
- Affected code: All files in `supabase/tests/`
- No behavioral changes - same tests, better organization
