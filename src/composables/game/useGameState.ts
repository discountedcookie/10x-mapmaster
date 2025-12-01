import { computed, ref, type Component } from 'vue'
import { useGameSessionStore } from '@/stores/gameSession'
import GameLoading from '@/components/game/states/GameLoading.vue'
import GameError from '@/components/game/states/GameError.vue'
import GameActive from '@/components/game/states/GameActive.vue'
import GameWon from '@/components/game/states/GameWon.vue'
import GameSubmission from '@/components/game/states/GameSubmission.vue'
import GameSubmissionPending from '@/components/game/states/GameSubmissionPending.vue'

export type StateView = {
  component: Component
  props: Record<string, unknown>
}

/**
 * Composable for managing game view state and component selection.
 * Returns the appropriate state component and its props based on current game state.
 */
export function useGameState() {
  const gameSessionStore = useGameSessionStore()
  const loadError = ref<string | undefined>()

  // Derive state view - component and props together
  const stateView = computed<StateView | null>(() => {
    const title = gameSessionStore.session?.description ?? undefined

    if (loadError.value) {
      return { component: GameError, props: { error: loadError.value } }
    }

    if (gameSessionStore.loading && !gameSessionStore.session) {
      return { component: GameLoading, props: {} }
    }

    if (!gameSessionStore.session) {
      return null
    }

    if (gameSessionStore.isWon) {
      return { component: GameWon, props: { title } }
    }
    if (gameSessionStore.isSubmissionPending) {
      return { component: GameSubmissionPending, props: { title } }
    }
    if (gameSessionStore.isNeedsSubmission) {
      return { component: GameSubmission, props: {} }
    }
    if (gameSessionStore.isGameActive) {
      return { component: GameActive, props: { title } }
    }

    return null
  })

  return {
    loadError,
    stateView,
  }
}
