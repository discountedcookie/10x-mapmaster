## 1. Add Auth Ready Promise

- [x] 1.1 Add `readyPromise` private ref to auth store
- [x] 1.2 Add `whenReady()` method that returns the promise
- [x] 1.3 Resolve promise in `initialize()` when auth completes
- [x] 1.4 Handle case where `whenReady()` called before `initialize()`

## 2. Fix Router Guard

- [x] 2.1 Replace while-loop with `await authStore.whenReady()`
- [x] 2.2 Remove the 50ms setTimeout polling pattern

## 3. Add Lazy Loading

- [x] 3.1 Convert HomeView import to `() => import('@/views/HomeView.vue')`
- [x] 3.2 Convert GameView import to lazy
- [x] 3.3 Convert LoginView import to lazy
- [x] 3.4 Convert SignupView import to lazy
- [x] 3.5 Convert StatisticsView import to lazy
- [x] 3.6 Convert PlaceView import to lazy

## 4. Verify

- [x] 4.1 Run `bun run build` - check for code splitting in output
- [x] 4.2 Test navigation to protected routes
- [x] 4.3 Test navigation during auth initialization
