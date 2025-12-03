## 1. Failure Inventory

- [ ] 1.1 Run `bun run test:unit` and capture all failing tests and their error messages.
- [ ] 1.2 Categorize failures (imports, mocks, assertion mismatches, environment assumptions).

## 2. Core Fixes

- [ ] 2.1 Fix the game store tests to import the correct store (`useGameSessionStore`) and adjust setup accordingly.
- [ ] 2.2 Add a proper mock for `@indoorequal/vue-maplibre-gl` that includes `useMap` for `App.spec.ts` and any map-dependent tests.
- [ ] 2.3 Update `GamePlaceSearch.spec.ts` expectations to match current DOM structure and i18n strings.
- [ ] 2.4 Align tests for error state nullability and statistics behavior with updated store/composable conventions (ties into `fix-store-error-nullability`).

## 3. Verification

- [ ] 3.1 Re-run targeted tests for each fixed suite.
- [ ] 3.2 Run `bun run test:unit` and confirm all tests pass.
- [ ] 3.3 Note any remaining brittle tests that should be refactored in future proposals.
