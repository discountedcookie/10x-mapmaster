## 1. Audit Type Violations

- [ ] 1.1 List all `@ts-ignore` comments in src/
- [ ] 1.2 List all `eslint-disable.*any` comments in src/
- [ ] 1.3 List all `as any` and `as unknown` casts in src/
- [ ] 1.4 Categorize by root cause (Supabase, MapLibre, missing types)

## 2. Fix Supabase Typing

- [ ] 2.1 Fix `useStatistics.ts` - use proper RPC generic typing
- [ ] 2.2 Fix `useRealtimePlaces.ts` - type the payload correctly
- [ ] 2.3 Regenerate database types if schema has changed

## 3. Fix Store Typing

- [ ] 3.1 Fix `HomeView.vue` - remove places array `any` casts
- [ ] 3.2 Fix `PlaceView.vue` - remove store data `any` casts
- [ ] 3.3 Fix `gameSearch.ts` - type event handlers properly

## 4. Fix Map Typing

- [ ] 4.1 Add type definitions for custom map data structures
- [ ] 4.2 Fix `useGameMap.ts` - remove `any` for map events
- [ ] 4.3 Fix `PlaceView.vue` - type map-related data

## 5. Verify

- [ ] 5.1 Run `bun run type-check` with zero errors
- [ ] 5.2 Confirm no `eslint-disable` comments for type rules remain
- [ ] 5.3 Run `bun run lint` to verify no lint errors
