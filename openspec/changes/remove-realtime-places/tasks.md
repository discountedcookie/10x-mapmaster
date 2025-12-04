## 1. Delete Realtime Composable

- [x] 1.1 Delete `src/composables/useRealtimePlaces.ts`

## 2. Simplify Places Store

- [x] 2.1 Remove `addPlace` action from `src/stores/places.ts`
- [x] 2.2 Remove `updatePlace` action from `src/stores/places.ts`
- [x] 2.3 Remove `removePlace` action from `src/stores/places.ts`

## 3. Update Tests

- [x] 3.1 Remove `addPlace` tests from `src/__tests__/stores/places.spec.ts`
- [x] 3.2 Remove `updatePlace` tests from `src/__tests__/stores/places.spec.ts`
- [x] 3.3 Remove `removePlace` tests from `src/__tests__/stores/places.spec.ts`
- [x] 3.4 Remove unused Supabase channel mocks from test file

## 4. Verify

- [x] 4.1 Run `bun run test` to confirm tests pass
- [x] 4.2 Run `bun run type-check` to confirm no type errors
