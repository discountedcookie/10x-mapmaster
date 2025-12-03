# Change: Add Unit Tests for Map Composables

## Why

Map-related composables (e.g., `useMapCamera`, `useAutoRotation`, `useGlobeVisibility`) currently lack dedicated unit tests, despite encapsulating non-trivial UI behavior. This makes refactors risky and regressions hard to catch.

## What Changes

- Design and implement unit tests for all map-related composables under `src/composables/map/`.
- Capture critical behaviors such as camera state sync, auto-rotation toggling, intro sequences, and derived presentation state.
- Ensure map composables are testable with mocks for MapLibre/deck.gl dependencies.

## Impact

- Affected specs: `frontend` (composables and testing).
- Affected code: `src/composables/map/*.ts` and new tests in `src/__tests__/composables/map/*.spec.ts`.
- Increases confidence when evolving map behavior and camera interactions.
