## 1. Add Store Actions

- [ ] 1.1 Add `addPlace(place: Place)` action to places store
- [ ] 1.2 Add `updatePlace(id: string, place: Place)` action
- [ ] 1.3 Add `removePlace(id: string)` action
- [ ] 1.4 Ensure actions maintain sort order by name

## 2. Refactor useRealtimePlaces

- [ ] 2.1 Replace direct `push()` with `placesStore.addPlace()`
- [ ] 2.2 Replace direct array assignment with `placesStore.updatePlace()`
- [ ] 2.3 Replace direct `splice()` with `placesStore.removePlace()`
- [ ] 2.4 Remove type casting workarounds (`as unknown as`)

## 3. Fix gameSearch Cross-Store

- [ ] 3.1 Move `useGameSessionStore()` call to store setup level
- [ ] 3.2 Update `isSubmissionPending` computed to use the setup-level instance

## 4. Verify

- [ ] 4.1 Run `bun run test:unit` to verify store tests pass
- [ ] 4.2 Test realtime updates in browser with Vue devtools
- [ ] 4.3 Verify devtools shows action names for mutations
