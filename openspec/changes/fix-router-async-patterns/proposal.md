# Change: Fix Router Async Patterns

## Why

The router navigation guard uses a busy-wait polling loop to wait for auth initialization:

```typescript
while (authStore.loading) {
  await new Promise((resolve) => setTimeout(resolve, 50))
}
```

This wastes CPU cycles and is an anti-pattern. Additionally, all view components are eagerly imported, increasing initial bundle size and slowing first paint.

## What Changes

- Replace busy-wait with promise-based `authStore.whenReady()` method
- Convert all route components to lazy imports using `() => import(...)`
- Use VueUse's `promiseTimeout` or native Promise for cleaner async handling

## Impact

- Affected specs: `frontend` (Router configuration)
- Affected code:
  - `src/router/index.ts` - Lazy imports + async pattern
  - `src/stores/auth.ts` - Add `whenReady()` method
