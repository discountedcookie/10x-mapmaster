# Change: Standardize Store Error Nullability

## Why

Stores and composables currently use a mix of `undefined` and `null` for error state, causing confusion and test failures. Supabase patterns favor `null` for "no error", and tests should align with that convention.

## What Changes

- Standardize error state initialization and reset behavior on `null` (e.g., `Ref<string | null>`), not `undefined`.
- Update unit tests to expect `null` as the empty error state.
- Ensure any shared helpers (e.g., loading/error wrappers) follow this convention.

## Impact

- Affected specs: `frontend` (state management conventions).
- Affected code: stores and composables using `error` refs (`usePlacesStore`, `useStatistics`, and any others), and their associated tests.
- Tests will consistently reflect the intended Supabase-style nullability and reduce brittle assertions.
