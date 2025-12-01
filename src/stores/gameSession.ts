import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { logger } from '@/lib/logger'
import { gameApi, type GameSessionStateRow } from '@/lib/api'
import { withLoadingState } from '@/lib/errors'

export const useGameSessionStore = defineStore('gameSession', () => {
  // Core state mirrors the game_session_state view
  const session = ref<GameSessionStateRow | null>(null)
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)

  /**
   * Fetch game state from game_session_state view
   */
  async function fetchGameState(sessionIdParam: string): Promise<void> {
    const data = await gameApi.getGameState(sessionIdParam)
    session.value = data
  }

  /**
   * Start new game
   */
  async function startNewGame(description: string, languageCode: string = 'en'): Promise<void> {
    if (!description.trim()) {
      error.value = 'Description cannot be empty'
      return
    }

    const result = await withLoadingState(
      async () => {
        const newSessionId = await gameApi.startGame(description, languageCode)
        await fetchGameState(newSessionId)
        return newSessionId
      },
      loading,
      error
    )

    if (!result) {
      logger.error('Failed to start new game')
    }
  }

  /**
   * Answer current question / guess
   */
  async function answer(answer: boolean): Promise<void> {
    const currentSessionId = session.value?.session_id
    if (!currentSessionId) {
      error.value = 'No active game'
      return
    }

    const answerValue: 'yes' | 'no' = answer ? 'yes' : 'no'

    await withLoadingState(
      async () => {
        await gameApi.playTurn(currentSessionId, answerValue)
        await fetchGameState(currentSessionId)
      },
      loading,
      error
    )
  }

  /**
   * Submit the actual place when the game fails to guess
   */
  async function submitPlace(osmId: string): Promise<void> {
    const currentSessionId = session.value?.session_id
    if (!currentSessionId) {
      error.value = 'No active game'
      return
    }

    await withLoadingState(
      async () => {
        await gameApi.submitPlace(currentSessionId, osmId)
        await fetchGameState(currentSessionId)
      },
      loading,
      error
    )
  }

  /**
   * Refresh current session from backend
   * If sessionIdParam is provided, it overrides current session id.
   */
  async function refresh(sessionIdParam?: string): Promise<void> {
    const targetSessionId = sessionIdParam ?? session.value?.session_id

    if (!targetSessionId) {
      error.value = 'No active game'
      return
    }

    await withLoadingState(
      async () => {
        await fetchGameState(targetSessionId)
      },
      loading,
      error
    )
  }

  /**
   * Reset game state
   */
  function resetGame(): void {
    session.value = null
    loading.value = false
    error.value = undefined
  }

  // Minimal status helpers (temporary, to be removed once call sites use session.status directly)
  const isGameActive = computed(() => session.value?.status === 'active')
  const isGameEnded = computed(() => {
    const status = session.value?.status
    return status === 'won' || status === 'needs_submission' || status === 'ended'
  })
  const isNeedsSubmission = computed(() => session.value?.status === 'needs_submission')
  const isWon = computed(() => session.value?.status === 'won')
  const isSubmissionPending = computed(() => session.value?.status === 'ended')

  return {
    session,
    loading,
    error,
    // status helpers (bridge for existing call sites)
    isGameActive,
    isGameEnded,
    isNeedsSubmission,
    isWon,
    isSubmissionPending,
    // actions
    startNewGame,
    answer,
    submitPlace,
    refresh,
    resetGame,
  }
})
