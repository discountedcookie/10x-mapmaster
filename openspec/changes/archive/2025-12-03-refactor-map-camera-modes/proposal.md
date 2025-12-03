# Change: Refactor Map Camera Management with Unified Modes

## Why

The map camera behavior is currently fragmented across views with duplicated logic. PlaceView implements its own rotation (332-429 lines), GameView has separate win-state camera handling, and there's no shared "place presentation" mode. This leads to:

1. **Duplicated code** - PlaceView reimplements rotation instead of using `useAutoRotation`
2. **Inconsistent behavior** - GameView win state doesn't rotate, PlaceView does
3. **Missing features** - No zoom-pitch correlation, no interaction restrictions, no smart resets
4. **Poor UX** - Abrupt pitch changes when zooming out to globe view

## What Changes

### Camera Modes

- **Idle mode** (Home): Cinematic intro on refresh, then place-to-place rotation. User interaction pauses; resumes after timeout.
- **Place Presentation mode** (PlaceView, GameView win/submission): Zoom to place with pitch, continuous orbital rotation. User can zoom in/out with pitch correlation.
- **Candidates mode** (GameView active): Fit all candidates on screen, standard map controls.

### Interaction Behaviors

- **Zoom-pitch correlation**: Pitch scales from 0° (globe view, zoom ≤2) to 55° (close view, zoom ≥12) with smooth interpolation
- **Place Presentation restrictions**: GameView presentation allows zoom-only; PlaceView allows pan (navigating away resets URL to home)
- **Smart reset on pan**: When user pans away from presented place, reset pitch to 0° and rotation to north, then optionally resume idle rotation after delay

### Shared Composables

- Extract `usePlacePresentation()` from PlaceView for reuse in GameView win state
- Add `useZoomPitchCorrelation()` for smooth pitch adjustment on zoom changes
- Add interaction mode configuration to `useMapCamera`

## Impact

- Affected specs: `frontend`
- Affected code:
  - `src/composables/map/useMapCamera.ts` - Add interaction modes
  - `src/composables/map/usePlacePresentation.ts` - New shared composable
  - `src/composables/map/useZoomPitchCorrelation.ts` - New composable
  - `src/views/PlaceView.vue` - Refactor to use shared composable
  - `src/views/GameView.vue` - Add presentation mode for win/submission
  - `src/views/HomeView.vue` - Add smart resume after pan-away
