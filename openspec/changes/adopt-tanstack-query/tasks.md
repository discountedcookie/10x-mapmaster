## 1. Setup TanStack Query

- [ ] 1.1 Install `@tanstack/vue-query` package
- [ ] 1.2 Create QueryClient in `src/lib/query.ts`
- [ ] 1.3 Add VueQueryPlugin to `src/main.ts`
- [ ] 1.4 Add QueryDevtools component (dev only)

## 2. Migrate Places Data

- [ ] 2.1 Create `src/composables/queries/usePlacesQuery.ts`
- [ ] 2.2 Implement `useQuery` with `['places']` key
- [ ] 2.3 Update components to use new query composable
- [ ] 2.4 Remove manual caching from `places.ts` store
- [ ] 2.5 Keep store for non-server state (search UI state)

## 3. Migrate Statistics Data

- [ ] 3.1 Create `src/composables/queries/useStatisticsQuery.ts`
- [ ] 3.2 Implement queries for user and global stats
- [ ] 3.3 Update `StatisticsView.vue` to use queries
- [ ] 3.4 Remove `useStatistics.ts` composable

## 4. Migrate Game Session Data

- [ ] 4.1 Create `src/composables/queries/useGameSessionQuery.ts`
- [ ] 4.2 Implement query with session ID as key
- [ ] 4.3 Update `gameSession.ts` store to use query internally
- [ ] 4.4 Keep mutations in store (start_game, play_turn, submit_place)

## 5. Verify

- [ ] 5.1 Run `bun run test:unit` to verify tests pass
- [ ] 5.2 Test deduplication by triggering multiple fetches
- [ ] 5.3 Verify DevTools shows cache state correctly
- [ ] 5.4 Test background refetching behavior
