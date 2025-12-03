## 1. Failure Inventory

- [x] 1.1 Run `bun run test:unit` and capture all failing tests and their error messages.
- [x] 1.2 Categorize failures (imports, mocks, assertion mismatches, environment assumptions).

## 2. Core Fixes

- [x] 2.1 Fix the game store tests to import the correct store (`useGameSessionStore`) and adjust setup accordingly.
- [x] 2.2 Add a proper mock for `@indoorequal/vue-maplibre-gl` that includes `useMap` for `App.spec.ts` and any map-dependent tests.
- [x] 2.3 Update `GamePlaceSearch.spec.ts` expectations to match current DOM structure and i18n strings.
- [x] 2.4 Align tests for error state nullability and statistics behavior with updated store/composable conventions (ties into `fix-store-error-nullability`).

## 3. Verification

- [x] 3.1 Re-run targeted tests for each fixed suite.
- [x] 3.2 Run `bun run test:unit` and confirm all tests pass.
- [x] 3.3 Note any remaining brittle tests that should be refactored in future proposals.

## Notes

### Brittle Tests for Future Refactoring

1. **Test file line limits**: Several test files exceed the 200-line limit (`game.spec.ts`, `places.spec.ts`, `useStatistics.spec.ts`). Consider splitting into smaller, focused test files.

2. **Pre-existing lint issue**: `src/i18n/types.ts:12` has an `@typescript-eslint/no-empty-object-type` error unrelated to tests.
