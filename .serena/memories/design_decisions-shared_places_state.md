## Shared Places State - Singleton Pattern (October 21, 2025)

**Problem**: Places were being fetched separately in HomeView and GameView, causing map to reload and jump when navigating between views.

**Solution**: Convert `usePlaces` composable to singleton pattern with shared state.

**Implementation**:
```typescript
// Shared state at module level (outside composable function)
const places = ref<Place[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
let fetchPromise: Promise<void> | null = null

export function usePlaces() {
  async function fetchAllPlaces() {
    // If already loaded, don't fetch again
    if (places.value.length > 0) {
      return
    }
    
    // If already fetching, return existing promise (prevents race conditions)
    if (fetchPromise) {
      return fetchPromise
    }
    
    // ... fetch logic
  }
}
```

**Benefits**:
- Places fetched only once per session
- No map jumping when switching views
- Shared reactive state across components
- Prevents race conditions (multiple simultaneous fetches)
- Better performance (one network request instead of multiple)
