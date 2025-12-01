# Change: Refactor GameView into State-Based Components

## Why

GameView.vue is 470 lines - over 2x the 200-line project limit. It handles 6 different game states via nested v-if chains, mixes camera orchestration with UI rendering, and is difficult to maintain. The rest of the app uses clean router-based view separation, but GameView acts as an implicit "state router" without the organizational benefits.

## What Changes

- Split GameView into state-specific components using dynamic `<component :is="..." />` pattern
- Each state component handles its own map controls (camera, 3D layers, presentation)
- GameView becomes thin orchestrator (~100 lines) managing only candidates layer and state composition
- Extract shared map utilities to composables

## Impact

- Affected specs: `frontend` (Gameplay UI requirement)
- Affected code:
  - `src/views/GameView.vue` - Refactor to thin orchestrator
  - `src/components/game/states/` - New state components (6 files)
  - `src/composables/game/` - New game-specific composables
  - `src/lib/map-utils.ts` - New shared utilities
