# Change: Remove Realtime Places Subscription

## Why

Realtime updates for places adds complexity without value. Places are added infrequently (only when users win games), no user scenario requires instant visibility of new places, and the current implementation is incomplete (table not in `supabase_realtime` publication).

## What Changes

- Delete `useRealtimePlaces` composable
- Remove mutation actions (`addPlace`, `updatePlace`, `removePlace`) from places store
- Remove tests for mutation actions
- Remove "Store Mutation Pattern" requirement from frontend spec

## Impact

- Affected specs: frontend
- Affected code: `src/composables/useRealtimePlaces.ts`, `src/stores/places.ts`, `src/__tests__/stores/places.spec.ts`
