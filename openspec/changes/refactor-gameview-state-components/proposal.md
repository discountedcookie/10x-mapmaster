# Change: Refactor GameView into State-Based Components

## Why

GameView.vue is 470 lines - over 2x the 200-line project limit. It handles 6 different game states via nested v-if chains, mixes camera orchestration with UI rendering, and is difficult to maintain. The rest of the app uses clean router-based view separation, but GameView acts as an implicit "state router" without the organizational benefits.

Additionally, map responsibilities are leaking into the wrong places:

- `GameView` manually watches candidates and calls `registerCandidatesLayer()` - this should be in the composable
- `GameActive` computes bounds and calls `camera.fitBounds()` directly - camera logic belongs in map composables
- State components know about `mapLayersStore` internals

## What Changes

- Split GameView into state-specific components using dynamic `<component :is="..." />` pattern
- **Encapsulate map layer management in `useGameMap`** - composable owns layer registration, not views
- **Encapsulate camera behavior in map composables** - state components express intent, composables handle MapLibre
- GameView becomes thin orchestrator (~100 lines) with no direct map layer management
- State components are pure UI - they consume data but don't touch map internals

## Impact

- Affected specs: `frontend` (Gameplay UI requirement, Map Visualization)
- Affected code:
  - `src/views/GameView.vue` - Refactor to thin orchestrator, remove map watches
  - `src/components/game/states/` - Pure UI, no map layer/camera code
  - `src/composables/game/useGameMap.ts` - Owns candidates layer lifecycle, camera fitting
  - `src/lib/map-utils.ts` - Shared utilities
