# Change: Fix Type Safety Violations

## Why

The codebase has 15+ instances of `@ts-ignore`, `eslint-disable @typescript-eslint/no-explicit-any`, and type casting to `any` or `unknown`. These indicate incomplete type definitions that undermine TypeScript's value:

- `src/views/HomeView.vue` - 3 `any` casts for places array
- `src/views/PlaceView.vue` - 8 `any` casts for store and map data
- `src/composables/useStatistics.ts` - `supabase as any` cast
- `src/composables/useRealtimePlaces.ts` - `as unknown as` casts
- `src/stores/gameSearch.ts` - `any` for event handling

These are "type safety theater" - the code looks typed but isn't.

## What Changes

- Fix Supabase client typing for RPC calls
- Add proper types for map-related data structures
- Remove `any` casts by using correct generic parameters
- Update generated database types if needed

## Impact

- Affected specs: `frontend` (Type safety)
- Affected code:
  - Multiple view and composable files
  - `src/types/` - May need additional type definitions
