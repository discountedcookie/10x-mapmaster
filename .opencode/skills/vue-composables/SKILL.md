---
name: vue-composables
description: >-
  Use when creating reusable composables, managing reactive state, or implementing
  the Composition API. Load for useX patterns, Pinia store patterns, withLoadingState
  helper, lifecycle management, and type-safe state patterns. Covers composable
  structure, error handling, and testing composables.
---

# Vue Composables

Composition API patterns for reusable logic.

> **Announce:** "I'm using vue-composables to implement reactive logic correctly."

## Composable Structure

Standard composable pattern:

```typescript
// src/composables/useExample.ts
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

interface UseExampleOptions {
  initialValue?: number
  autoFetch?: boolean
}

interface UseExampleReturn {
  value: Ref<number>
  doubled: ComputedRef<number>
  increment: () => void
  reset: () => void
}

export function useExample(options: UseExampleOptions = {}): UseExampleReturn {
  // 1. Destructure options with defaults
  const { initialValue = 0, autoFetch = true } = options
  
  // 2. Create reactive state
  const value = ref(initialValue)
  
  // 3. Create computed values
  const doubled = computed(() => value.value * 2)
  
  // 4. Create methods
  function increment(): void {
    value.value++
  }
  
  function reset(): void {
    value.value = initialValue
  }
  
  // 5. Lifecycle hooks
  onMounted(() => {
    if (autoFetch) {
      // Initial fetch
    }
  })
  
  // 6. Return public API
  return {
    value,
    doubled,
    increment,
    reset
  }
}
```

## Async Composable Pattern

For data fetching:

```typescript
export function useGameSession(sessionId: string) {
  const session = ref<GameSession | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetch(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .rpc('get_session', { p_session_id: sessionId })
      if (err) throw err
      session.value = data
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Unknown error'
      session.value = null  // IMPORTANT: Clear on error
    } finally {
      loading.value = false
    }
  }

  onMounted(() => fetch())

  return { 
    session: readonly(session),  // Prevent external mutation
    loading: readonly(loading),
    error: readonly(error),
    refetch: fetch 
  }
}
```

## withLoadingState Helper

Centralized loading/error handling:

```typescript
// src/lib/errors.ts
export async function withLoadingState<T>(
  fn: () => Promise<T>,
  loading: Ref<boolean>,
  error: Ref<string | null>
): Promise<T | undefined> {
  try {
    loading.value = true
    error.value = null
    return await fn()
  } catch (e) {
    const apiError = transformError(e)
    error.value = apiError.message
    logger.error('Operation failed', { error: apiError })
    return undefined
  } finally {
    loading.value = false
  }
}

// Usage in store
async function startGame(description: string): Promise<void> {
  await withLoadingState(async () => {
    const sessionId = await gameApi.startGame(description)
    await fetchGameState(sessionId)
  }, loading, error)
}
```

## Pinia Store Pattern

Setup syntax with clear sections:

```typescript
// src/stores/gameSession.ts
export const useGameSessionStore = defineStore('gameSession', () => {
  // === STATE ===
  const session = ref<GameSessionStateRow | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  // === GETTERS (computed) ===
  const isGameActive = computed(() => session.value?.status === 'active')
  const currentQuestion = computed(() => session.value?.next_turn?.question)
  const candidates = computed(() => session.value?.next_turn?.candidates ?? [])
  
  // === ACTIONS ===
  async function startNewGame(description: string): Promise<void> {
    await withLoadingState(async () => {
      const sessionId = await gameApi.startGame(description)
      await fetchGameState(sessionId)
    }, loading, error)
  }
  
  async function fetchGameState(sessionId: string): Promise<void> {
    const { data } = await supabase
      .from('game_session_state')
      .select('*')
      .eq('id', sessionId)
      .single()
    session.value = data
  }
  
  function reset(): void {
    session.value = null
    error.value = null
  }
  
  // === RETURN ===
  return {
    // State
    session,
    loading,
    error,
    // Getters
    isGameActive,
    currentQuestion,
    candidates,
    // Actions
    startNewGame,
    fetchGameState,
    reset
  }
})
```

## Cleanup Pattern

Always clean up resources:

```typescript
export function useMapEvents(mapKey: symbol) {
  const map = inject<MapLibreMap>(mapKey)
  
  function handleClick(e: MapMouseEvent) { ... }
  function handleMove(e: MapMouseEvent) { ... }
  
  onMounted(() => {
    if (!map) return
    map.on('click', handleClick)
    map.on('move', handleMove)
  })
  
  onUnmounted(() => {
    if (!map) return
    map.off('click', handleClick)
    map.off('move', handleMove)
  })
  
  return { /* ... */ }
}
```

## Anti-Patterns

### DON'T: Return Unwrapped Refs

```typescript
// WRONG: Consumers can mutate directly
return { session }

// CORRECT: Use readonly for read-only values
return { session: readonly(session) }
```

### DON'T: Skip Error State

```typescript
// WRONG: No error handling
async function fetch() {
  const { data } = await supabase.rpc('something')
  value.value = data
}

// CORRECT: Track errors
async function fetch() {
  try {
    error.value = null
    const { data, error: err } = await supabase.rpc('something')
    if (err) throw err
    value.value = data
  } catch (e) {
    error.value = e.message
  }
}
```

### DON'T: Forget Mounted Check for Async

```typescript
// WRONG: May update refs after unmount
async function fetch() {
  const data = await fetchData()
  value.value = data  // Component might be unmounted!
}

// CORRECT: Check if still mounted
let isMounted = true
onUnmounted(() => { isMounted = false })

async function fetch() {
  const data = await fetchData()
  if (isMounted) value.value = data
}
```

## Testing Composables

```typescript
// src/__tests__/composables/useExample.spec.ts
import { describe, it, expect } from 'vitest'
import { useExample } from '@/composables/useExample'

describe('useExample', () => {
  it('initializes with default value', () => {
    const { value } = useExample()
    expect(value.value).toBe(0)
  })

  it('accepts initial value', () => {
    const { value } = useExample({ initialValue: 10 })
    expect(value.value).toBe(10)
  })

  it('increments value', () => {
    const { value, increment } = useExample()
    increment()
    expect(value.value).toBe(1)
  })
})
```

## References

See `references/composable-examples.md` for more patterns.
