## 1. Audit Error States

- [x] 1.1 Identify all stores and composables with `error` refs in `src/stores` and `src/composables`.
- [x] 1.2 Decide and document the canonical type for error state (e.g., `Ref<string | null>` or a union including `Error`).

## 2. Implement Null Defaults

- [x] 2.1 Update `usePlacesStore` to initialize `error` as `null` and reset it to `null` on success.
- [x] 2.2 Update `useStatistics` to initialize and reset `error` to `null` consistently.
- [x] 2.3 Update any helpers (such as `withLoadingState`) that implicitly assume `undefined` for error.

## 3. Update Tests

- [x] 3.1 Update `src/__tests__/stores/places.spec.ts` to expect `null` for error in initial and reset states.
- [x] 3.2 Update `src/__tests__/composables/useStatistics.spec.ts` to expect `null` for error and align initial statistics expectations.
- [x] 3.3 Run unit tests for the affected suites and adjust any remaining assertions relying on `undefined`.
