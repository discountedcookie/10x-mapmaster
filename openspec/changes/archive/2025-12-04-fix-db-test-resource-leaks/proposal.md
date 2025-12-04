# Change: Fix Resource Leak Warnings in Database Tests

## Why

pgTAP test runs emit `TupleDesc` resource leak warnings for a few test files. While tests still pass, these warnings indicate improper cleanup of query resources and can hide deeper issues or make debugging harder.

## What Changes

- Identify and fix the queries or function calls in tests that leave `TupleDesc` resources open.
- Adopt patterns (e.g., `PERFORM` or full result consumption) that ensure resources are properly released.
- Keep test behavior unchanged while eliminating warnings.

## Impact

- Affected specs: `database` (test quality and maintenance).
- Affected code: `supabase/tests/test_game_basics.sql`, `supabase/tests/test_geographic_filtering.sql`, `supabase/tests/test_settings_control_behavior.sql`.
- Results in cleaner test runs and more maintainable database tests.
