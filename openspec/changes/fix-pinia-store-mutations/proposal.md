# Change: Fix Pinia Store Mutations

## Why

The `useRealtimePlaces` composable directly mutates the Pinia store's reactive array:

```typescript
const places = placesStore.places as unknown as PlaceRecord[]
places.push(placeData) // Direct mutation!
places.splice(index, 1) // Direct mutation!
```

This bypasses Pinia's action tracking, breaks Vue devtools time-travel debugging, and can cause subtle reactivity bugs. Pinia stores should only be mutated through actions.

Additionally, `gameSearch.ts` calls `useStore()` inside a computed, which is fragile.

## What Changes

- Add `addPlace`, `updatePlace`, `removePlace` actions to places store
- Refactor `useRealtimePlaces` to use store actions instead of direct mutation
- Move cross-store access in `gameSearch.ts` to store setup level

## Impact

- Affected specs: `frontend` (State management)
- Affected code:
  - `src/stores/places.ts` - Add CRUD actions
  - `src/composables/useRealtimePlaces.ts` - Use actions
  - `src/stores/gameSearch.ts` - Fix cross-store pattern
