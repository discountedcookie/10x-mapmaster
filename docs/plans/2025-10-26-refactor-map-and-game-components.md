# Refactor Map Layout and Game View Components

**Date:** 2025-10-26
**Status:** Approved
**Context:** MapLayout contains mode-detection logic and GameView is 384 lines with mixed concerns

## Goals

1. Extract marker/bounds logic from MapLayout - let views decide what to show
2. Decompose GameView into smaller, focused components
3. Extract business logic into composables
4. Achieve feature-based organization with clear ownership

## Design Principles

- **Single Responsibility:** Each component/composable does one thing well
- **Props Down, Events Up:** Components are presentational, emit events for actions
- **Composable Composition:** Small composables that combine into useGameFlow()
- **Feature-based Organization:** Game code lives together in composables/game/ and components/game/

## Architecture

### File Structure

```
src/
├── composables/
│   ├── game/
│   │   ├── useGameState.ts       # State machine & reactive state
│   │   ├── useGameActions.ts     # Business logic (start, answer, save)
│   │   ├── useGameValidation.ts  # Description validation
│   │   └── index.ts              # useGameFlow() - combines all above
│   └── map/
│       ├── useMapMarkers.ts      # Generic marker utilities
│       └── useMapBounds.ts       # Bounds calculation
├── components/
│   └── game/
│       ├── GameStartScreen.vue       # Description input screen
│       ├── GameResumeDialog.vue      # Resume/new game dialog
│       ├── GameLoadingOverlay.vue    # Loading state
│       ├── GameQuestionCard.vue      # Questions (renamed)
│       ├── GameResultCard.vue        # Results (renamed)
│       └── GamePlaceSearch.vue       # Place search (renamed)
├── views/
│   ├── GameView.vue              # Orchestrates game components (~60 lines)
│   └── HomeView.vue              # Computes markers for browse mode
└── layouts/
    └── MapLayout.vue             # Just renders map + slot (~30 lines)
```

## Component Responsibilities

### MapLayout.vue (~30 lines)
**Responsibility:** Render map and pass through slot content
**No Logic:** No mode detection, no marker computation, no bounds calculation

```vue
<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />
    <BaseMap>
      <slot /> <!-- Views provide their own markers -->
    </BaseMap>
    <slot name="overlay" /> <!-- For game cards, hero card, etc. -->
  </div>
</template>
```

### HomeView.vue (~40 lines)
**Responsibility:** Provide browse mode markers to map
**Uses:** `useMapMarkers()` to compute markers and bounds

```typescript
const { markers, bounds, markerNodes } = useMapMarkers({
  data: computed(() => placesStore.places),
  markerComponent: MapMarker,
  computeMarker: (place) => ({
    id: `place-${place.id}`,
    coordinates: [place.lng!, place.lat!],
    backgroundColor: '#3b82f6',
    opacity: 1,
    gameCount: place.game_count,
  })
})
```

### GameView.vue (~60 lines)
**Responsibility:** Orchestrate game flow and render appropriate component
**Uses:** `useGameFlow()` for state/actions, `useMapMarkers()` for map

```typescript
const gameFlow = useGameFlow()
const { markers, markerNodes } = useMapMarkers({
  data: computed(() => gameStore.topCandidates),
  markerComponent: MapMarker,
  computeMarker: (candidate) => ({
    id: `game-${candidate.id}`,
    coordinates: [candidate.lng!, candidate.lat!],
    backgroundColor: '#ef4444',
    opacity: 0.4 + (candidate.composite_confidence * 0.6),
  })
})

// Template switches components based on gameFlow.gameState
```

### Game UI Components

All game components follow the same pattern:
- **Pure presentation:** Receive data via props
- **Event emission:** Emit events for user actions
- **No business logic:** No store access, no async operations
- **Game prefix:** Clear feature ownership

**GameStartScreen.vue** (~80 lines)
- Props: description, validationMessage, isValid, loading
- Emits: update:description, start, goHome

**GameResumeDialog.vue** (~60 lines)
- Props: questionCount, candidatesCount
- Emits: resume, startFresh

**GameLoadingOverlay.vue** (~40 lines)
- Props: None (uses i18n for text)
- Emits: None (pure display)

**GameQuestionCard.vue** (renamed from QuestionCard)
- Existing component, just renamed for consistency

**GameResultCard.vue** (renamed from ResultCard)
- Existing component, just renamed for consistency

**GamePlaceSearch.vue** (renamed from PlaceSearch)
- Existing component, just renamed for consistency

## Composables Design

### useMapMarkers(options)

**Responsibility:** Generic marker rendering and bounds calculation
**Takes component as prop:** Flexible, reusable across views

```typescript
interface UseMapMarkersOptions<T> {
  data: ComputedRef<T[]>
  markerComponent: Component
  computeMarker: (item: T) => MarkerProps
}

function useMapMarkers<T>(options: UseMapMarkersOptions<T>) {
  const markers = computed(() => {
    return options.data.value
      .filter(item => item.lat && item.lng)
      .map(options.computeMarker)
  })

  const bounds = useMapBounds(markers)

  const markerNodes = computed(() => {
    return markers.value.map((marker, index) =>
      h(options.markerComponent, { ...marker, index })
    )
  })

  return { markers, bounds, markerNodes }
}
```

### useMapBounds(markers)

**Responsibility:** Calculate map bounds from marker coordinates
**Pure function:** Takes markers, returns bounds with padding

```typescript
function useMapBounds(markers: ComputedRef<Marker[]>, padding = 0.15) {
  return computed(() => {
    if (markers.value.length === 0) return undefined

    const lngs = markers.value.map(m => m.coordinates[0])
    const lats = markers.value.map(m => m.coordinates[1])

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    const lngPadding = (maxLng - minLng) * padding
    const latPadding = (maxLat - minLat) * padding

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ]
  })
}
```

### Game Composables

**useGameState.ts** (~50 lines)
- Manages: gameStarted, showResumeDialog, showPlaceSearch
- Computes: gameState (state machine)
- Returns: Reactive state refs and computed gameState

**useGameActions.ts** (~100 lines)
- All business logic: startGame, answerQuestion, handleCorrectGuess, etc.
- Depends on: useGameState, gameStore, placesStore
- Returns: Action functions

**useGameValidation.ts** (~30 lines)
- Validates: description length and format
- Computes: isValid, validationMessage, descriptionLength
- Returns: Validation state

**useGameFlow.ts** (index.ts) (~20 lines)
- Combines: useGameState + useGameActions + useGameValidation
- Provides: Single interface for GameView
- Returns: Complete game flow API

```typescript
export function useGameFlow() {
  const state = useGameState()
  const description = ref('')
  const validation = useGameValidation(description)
  const actions = useGameActions(state)

  return {
    ...state,
    ...actions,
    description,
    ...validation
  }
}
```

## Migration Strategy

1. **Create new composables:** Start with map composables (useMapMarkers, useMapBounds)
2. **Update HomeView:** Use new composables, verify browse mode works
3. **Create game UI components:** GameStartScreen, GameResumeDialog, GameLoadingOverlay
4. **Create game composables:** useGameState → useGameValidation → useGameActions → useGameFlow
5. **Refactor GameView:** Use new composables and components
6. **Rename existing components:** QuestionCard → GameQuestionCard, etc.
7. **Simplify MapLayout:** Remove all logic, just render map + slots
8. **Update imports:** Fix all import paths throughout app
9. **Test thoroughly:** Each mode (browse, game) and all game states
10. **Remove old code:** Delete unused logic from MapLayout

## Success Criteria

- [ ] MapLayout has no business logic (~30 lines)
- [ ] HomeView provides its own markers (~40 lines)
- [ ] GameView orchestrates components (~60 lines)
- [ ] All game components are <100 lines
- [ ] All game composables are <150 lines
- [ ] useGameFlow() provides clean API
- [ ] Browse mode shows all places with blue markers
- [ ] Game mode shows candidates with red markers based on confidence
- [ ] All game states render correctly (resume, start, question, result, place search)
- [ ] No regressions in functionality

## Trade-offs

**Pros:**
- Clear separation of concerns
- Reusable composables
- Easier to test and maintain
- Feature-based organization
- Smaller, focused files

**Cons:**
- More files to navigate
- Initial learning curve for new structure
- Import path updates required

## Future Considerations

- Could extract marker styling logic into separate functions
- Could create useGameSession() for session persistence
- Could add useGameAnalytics() for tracking game events
- Could generalize useMapMarkers() for other marker types
