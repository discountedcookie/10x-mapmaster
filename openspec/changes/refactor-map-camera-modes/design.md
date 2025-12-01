## Context

The map camera currently has fragmented control across three views (Home, Place, Game) with duplicated rotation logic and inconsistent behavior. This refactor consolidates camera management into composable, reusable modes.

**Stakeholders**: Frontend development, UX
**Constraints**: Must preserve existing MapLibre globe projection behavior, no backend changes required

## Goals / Non-Goals

**Goals:**

- Single source of truth for each camera mode
- Smooth UX transitions between modes
- Consistent interaction behavior across views
- Reusable composables for presentation and correlation logic

**Non-Goals:**

- Changing the map library (MapLibre)
- Adding new map features (layers, styles)
- Backend or database changes

## Decisions

### Decision 1: Three Camera Modes

Create three distinct camera modes, each with clear ownership:

| Mode         | Owner View(s)                        | Behavior                                                                     |
| ------------ | ------------------------------------ | ---------------------------------------------------------------------------- |
| Idle         | HomeView                             | Cinematic intro → place rotation, pause on interaction, resume after timeout |
| Presentation | PlaceView, GameView (win/submission) | Orbital rotation around place, zoom-pitch correlation                        |
| Candidates   | GameView (active)                    | Fit bounds to candidates, standard controls                                  |

**Rationale**: Clear mode separation prevents state conflicts and makes behavior predictable.

### Decision 2: Composable Architecture

```
useMapCamera (core)
├── useAutoRotation (idle mode - existing)
├── usePlacePresentation (new - extracted from PlaceView)
│   └── useZoomPitchCorrelation (new)
└── Interaction mode config (added to core)
```

**Rationale**: Composables can be mixed and matched by views. `usePlacePresentation` becomes the shared implementation for both PlaceView and GameView win state.

### Decision 3: Zoom-Pitch Interpolation Formula

```typescript
function getPitchForZoom(zoom: number): number {
  const MIN_ZOOM = 2 // Globe view
  const MAX_ZOOM = 12 // Close view
  const MIN_PITCH = 0 // Flat at globe
  const MAX_PITCH = 55 // Tilted when close

  const t = Math.max(0, Math.min(1, (zoom - MIN_ZOOM) / (MAX_ZOOM - MIN_ZOOM)))
  return MIN_PITCH + t * (MAX_PITCH - MIN_PITCH)
}
```

**Rationale**: Linear interpolation is simple and predictable. Users expect pitch to increase as they zoom in.

### Decision 4: Interaction Mode Configuration

Add to `useMapCamera`:

```typescript
type InteractionMode = 'full' | 'zoom-only' | 'none'

interface UseMapCameraOptions {
  interactionMode?: InteractionMode
  onUserInteraction?: () => void
}
```

**Rationale**: GameView presentation needs zoom-only (no pan), PlaceView needs full control. Central config prevents scattered event handling.

### Decision 5: Interaction Flow - PlaceView Pan-Away

When user pans in PlaceView, transition smoothly from "presentation mode" to "exploration mode":

1. **On touch/mousedown**: Orbital rotation stops immediately
2. **On pan start**: Begin smooth transition (500ms):
   - Pitch: 55° → 0° (flat view for exploration)
   - Bearing: current → 0° (north up)
3. **On release + 1.5s delay**: Check if place center is still visible
   - If visible: Stay on PlaceView, no rotation resumes (user is exploring nearby)
   - If not visible: Navigate to Home, keep map position

**Rationale**: The 55° pitch was useful for presenting _that specific place_. Once user pans away, they're in exploration mode where a flat view is more useful. Smooth transition during drag feels natural, not jarring.

### Decision 6: Interaction Flow - Zoom-Only Mode (GameView)

GameView win/submission presentation restricts interactions:

- Zoom in/out: Allowed (with pitch correlation)
- Pan: Ignored (drag events captured but not applied)
- Orbital rotation: Continues regardless of interaction

**Rationale**: User should see the winning place properly. Zooming lets them explore detail, but panning away would break the presentation.

### Decision 7: Smart Resume Timer

HomeView defines a single constant for rotation timing and uses it for both:

1. `pauseBetween` in `useAutoRotation` (pause between places)
2. Resume delay after user interaction

```typescript
const ROTATION_DELAY = 5000

const { start, stop, resume } = useAutoRotation({
  pauseBetween: ROTATION_DELAY,
  // ...
})

// Resume after user interaction uses same constant
setTimeout(resume, ROTATION_DELAY)
```

**Rationale**: Single constant, consistent timing feel, no duplication.

### Decision 8: Zoom-Pitch Correlation Trigger

Two distinct behaviors:

| User action                    | Pitch behavior                              |
| ------------------------------ | ------------------------------------------- |
| **Zoom only** (no pan)         | Pitch interpolates with zoom level          |
| **Pan** (with or without zoom) | Pitch resets to 0°, bearing resets to north |

**Rationale**: Zooming is "looking closer/further at the same thing". Panning is "looking at something else" - a stronger signal that user wants exploration mode.

## Risks / Trade-offs

| Risk                                             | Mitigation                                                |
| ------------------------------------------------ | --------------------------------------------------------- |
| Regression in existing behavior                  | Incremental refactor with tests at each step              |
| Performance impact from multiple animation loops | Only one mode active at a time, clean stop before switch  |
| Complexity from shared composables               | Clear documentation, single responsibility per composable |

## Migration Plan

1. Create new composables without changing existing code
2. Refactor PlaceView to use new composables (verify no regression)
3. Add presentation mode to GameView
4. Add smart resume to HomeView
5. Clean up any dead code from PlaceView

**Rollback**: Each step is independently deployable. Can revert to previous commit if issues found.

## Open Questions

- Should pitch correlation apply during idle mode place rotation? (Currently pitch=0 for idle, which works well for globe overview)
