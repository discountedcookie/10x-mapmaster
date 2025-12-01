## 1. Create Shared Utilities

- [ ] 1.1 Create `src/lib/map-utils.ts` with `calculateBounds()` helper
- [ ] 1.2 Create `src/composables/game/useGameMap.ts` for shared map ref and candidates layer

## 2. Create State Components

- [ ] 2.1 Create `src/components/game/states/GameLoading.vue` - Loading spinner state
- [ ] 2.2 Create `src/components/game/states/GameError.vue` - Error display with redirect
- [ ] 2.3 Create `src/components/game/states/GameActive.vue` - Question/Guess UI with camera controls
- [ ] 2.4 Create `src/components/game/states/GameWon.vue` - Victory state with fly-to animation
- [ ] 2.5 Create `src/components/game/states/GameSubmission.vue` - Place search for failed games
- [ ] 2.6 Create `src/components/game/states/GameEnded.vue` - Submission pending message
- [ ] 2.7 Create `src/components/game/states/index.ts` - Export state component map

## 3. Refactor GameView

- [ ] 3.1 Remove inline state rendering (v-if chains)
- [ ] 3.2 Import state component map and use `<component :is="..." />`
- [ ] 3.3 Move camera watch blocks to respective state components
- [ ] 3.4 Move 3D layer management to state components that need it
- [ ] 3.5 Keep only candidates layer management and state composition in GameView
- [ ] 3.6 Ensure GameView stays under 200 lines

## 4. Verification

- [ ] 4.1 Run `bun run lint` and fix any new errors
- [ ] 4.2 Run `bun run type-check` and fix any type errors
- [ ] 4.3 Manually test all game states work correctly
