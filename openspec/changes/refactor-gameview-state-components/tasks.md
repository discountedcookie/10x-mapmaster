## 1. Encapsulate Map Behavior in Composables

- [ ] 1.1 Update `src/composables/game/useGameMap.ts`:
  - Add internal `watch` for candidates/hideCircles/highlightedId
  - Call `registerCandidatesLayer` internally when data changes
  - Add `fitToCandidates()` method that handles camera fitting
  - Expose `hoveredCandidateId` ref for state components to write to
- [ ] 1.2 Ensure `src/lib/map-utils.ts` has `calculateBounds()` helper

## 2. Create/Update State Components (Pure UI)

- [ ] 2.1 Verify `GameLoading.vue` - No map code
- [ ] 2.2 Verify `GameError.vue` - No map code
- [ ] 2.3 Update `GameActive.vue`:
  - Remove `fitBoundsToCandidates` function
  - Remove `watch` blocks for camera/bounds
  - Only emit events and display data
- [ ] 2.4 Verify `GameWon.vue` - Uses composable for presentation, no direct camera calls
- [ ] 2.5 Verify `GameSubmission.vue` - Pure UI, no map code
- [ ] 2.6 Verify `GameSubmissionPending.vue` - Pure UI, no map code

## 3. Refactor GameView

- [ ] 3.1 Remove `watch` block that calls `registerCandidatesLayer`
- [ ] 3.2 Let `useGameMap` handle layer registration internally
- [ ] 3.3 Keep only state composition logic (dynamic component pattern)
- [ ] 3.4 Ensure no calls to `mapLayersStore` directly
- [ ] 3.5 Ensure GameView stays under 200 lines

## 4. Verification

- [ ] 4.1 Run `bun run lint` and fix any new errors
- [ ] 4.2 Run `bun run type-check` and fix any type errors
- [ ] 4.3 Verify no component outside composables calls `mapLayersStore`
- [ ] 4.4 Verify no state component calls `camera.fitBounds` directly
- [ ] 4.5 Manually test all game states work correctly
