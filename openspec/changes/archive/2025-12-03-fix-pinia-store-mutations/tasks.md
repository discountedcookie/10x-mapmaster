## 1. Add Store Actions

- [x] 1.1 Add `addPlace(place: Place)` action to places store
- [x] 1.2 Add `updatePlace(id: string, place: Place)` action
- [x] 1.3 Add `removePlace(id: string)` action
- [x] 1.4 Ensure actions maintain sort order by name

## 2. Refactor useRealtimePlaces

- [x] 2.1 Replace direct `push()` with `placesStore.addPlace()`
- [x] 2.2 Replace direct array assignment with `placesStore.updatePlace()`
- [x] 2.3 Replace direct `splice()` with `placesStore.removePlace()`
- [x] 2.4 Remove type casting workarounds (`as unknown as`)

## 3. Fix gameSearch Cross-Store

- [x] 3.1 Move `useGameSessionStore()` call to store setup level
- [x] 3.2 Update `isSubmissionPending` computed to use the setup-level instance

## 4. Verify

- [x] 4.1 Run `bun run test:unit` to verify store tests pass
- [x] 4.2 Test realtime updates in browser with Vue devtools
- [x] 4.3 Verify devtools shows action names for mutations
