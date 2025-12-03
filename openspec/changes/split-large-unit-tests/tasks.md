## 1. Plan Test Suite Splits

- [ ] 1.1 Analyze `src/__tests__/stores/game.spec.ts` and group tests by concern (e.g., initial state, actions, derived state, JSONB fallback).
- [ ] 1.2 Analyze `src/__tests__/stores/places.spec.ts` and group tests (e.g., core store behavior, fetchAll, search behavior, reset/isolation).
- [ ] 1.3 Analyze `src/__tests__/composables/useStatistics.spec.ts` and group tests (e.g., initial state, fetch logic, reactivity).

## 2. Create New Test Files

- [ ] 2.1 Create new files for logical groups (e.g., `gameSession.state.spec.ts`, `gameSession.actions.spec.ts`).
- [ ] 2.2 Move tests into the appropriate new files while preserving their assertions and setup.
- [ ] 2.3 Ensure shared setup/mocks are DRY, possibly via test helpers.

## 3. Verification

- [ ] 3.1 Run `bun run test:unit -- src/__tests__/stores` to confirm all moved tests still pass.
- [ ] 3.2 Run `bun run lint` to confirm ESLint no longer reports `max-lines` warnings for the affected test files.
