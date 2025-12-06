# RPC Patterns Reference

## API Module Structure

All RPC calls go through `src/lib/api/index.ts`:

```typescript
import { supabase } from '@/lib/supabase'

export const gameApi = {
  // Start a new game session
  async startGame(description: string, languageCode = 'en'): Promise<string> {
    const { data, error } = await supabase.rpc('start_game', {
      p_description: description,
      p_language_code: languageCode
    })
    if (error) throw error
    return data
  },

  // Play a turn (answer question or submit guess)
  async playTurn(sessionId: string, answer: 'yes' | 'no' | 'not_sure'): Promise<void> {
    const { error } = await supabase.rpc('play_turn', {
      p_session_id: sessionId,
      p_answer: answer
    })
    if (error) throw error
  },

  // Submit correct place when system was wrong
  async submitPlace(sessionId: string, osmId: string): Promise<void> {
    const { error } = await supabase.rpc('submit_correct_place', {
      p_session_id: sessionId,
      p_osm_id: osmId
    })
    if (error) throw error
  }
}
```

## Store Pattern

Stores call API module, not supabase directly:

```typescript
// src/stores/gameSession.ts
import { gameApi } from '@/lib/api'

export const useGameSessionStore = defineStore('gameSession', () => {
  const session = ref<GameSessionStateRow | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function startNewGame(description: string): Promise<void> {
    await withLoadingState(async () => {
      const sessionId = await gameApi.startGame(description)
      await fetchGameState(sessionId)
    }, loading, error)
  }

  async function fetchGameState(sessionId: string): Promise<void> {
    const { data, error: err } = await supabase
      .from('game_session_state')  // VIEW
      .select('*')
      .eq('id', sessionId)
      .single()
    
    if (err) throw err
    session.value = data
  }

  return { session, loading, error, startNewGame, fetchGameState }
})
```

## View Access Pattern

Read-only data comes from views:

```typescript
// Available views (read-only)
supabase.from('game_session_state').select('*')  // Current game state
supabase.from('places_with_geometry').select('*') // Place data for display
supabase.from('game_session_stats').select('*')   // Statistics
```

## What RPCs Return

RPCs return minimal data. Full state comes from views:

```sql
-- start_game returns just the session_id
RETURNS uuid

-- play_turn returns nothing (void)
-- State change happens, frontend re-fetches view

-- submit_correct_place returns nothing (void)
-- Triggers learning process in background
```

## Error Handling

Always use `withLoadingState` wrapper:

```typescript
import { withLoadingState } from '@/lib/errors'

async function doAction() {
  await withLoadingState(async () => {
    // API call here
  }, loading, error)
}
```
