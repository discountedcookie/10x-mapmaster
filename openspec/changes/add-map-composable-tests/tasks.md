## 1. Define Test Scenarios

- [ ] 1.1 For `useMapCamera`, define scenarios covering camera state synchronization, programmatic vs. user-initiated moves, and cleanup.
- [ ] 1.2 For `useAutoRotation`, define scenarios for starting/stopping rotation and pausing/resuming on user interaction.
- [ ] 1.3 For `useGlobeVisibility`, define visibility toggling scenarios and any dependencies on camera state.
- [ ] 1.4 For `useCinematicIntro`, define intro play/skip behavior and state transitions.
- [ ] 1.5 For `useMapCenterTracking`, define enabling/disabling center tracking and reaction to map events.
- [ ] 1.6 For `usePlacePresentation`, define conversion from places to marker/candidate structures.
- [ ] 1.7 For `useZoomPitchCorrelation`, define relationships between zoom and pitch calculations.

## 2. Implement Tests

- [ ] 2.1 Create `src/__tests__/composables/map` and add individual `*.spec.ts` files per composable.
- [ ] 2.2 Mock MapLibre/deck.gl-related APIs as needed in tests or shared setup.
- [ ] 2.3 Implement the defined test scenarios with focused, fast unit tests.

## 3. Verification

- [ ] 3.1 Run `bun run test:unit -- src/__tests__/composables/map`.
- [ ] 3.2 Adjust specs or tests if real-world behavior suggests additional scenarios are needed.
