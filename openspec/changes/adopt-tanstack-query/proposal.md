# Change: Adopt TanStack Query for Data Fetching

## Why

The current data fetching pattern uses manual deduplication logic:

```typescript
let fetchPromise: Promise<void> | undefined
async function fetchAllPlaces() {
  if (places.value.length > 0) return
  if (fetchPromise) return fetchPromise
  // ...
}
```

This is reinventing the wheel. TanStack Query (formerly React Query, now framework-agnostic) provides:

- Automatic request deduplication
- Caching with configurable stale time
- Background refetching
- Loading/error states out of the box
- DevTools for debugging

This is the industry standard for data fetching in modern apps.

## What Changes

- Add `@tanstack/vue-query` dependency
- Create query composables for places, statistics, game sessions
- Remove manual caching/deduplication code from stores
- Stores become thin wrappers or are eliminated

## Impact

- Affected specs: `frontend` (Data fetching patterns)
- Affected code:
  - `package.json` - Add dependency
  - `src/main.ts` - Setup QueryClient
  - `src/stores/places.ts` - Replace with query
  - `src/composables/useStatistics.ts` - Replace with query
  - `src/stores/gameSession.ts` - Replace fetch logic with query
