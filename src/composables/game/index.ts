import { ref, onMounted } from 'vue'
import { useGameState } from './useGameState'
import { useGameValidation } from './useGameValidation'
import { useGameActions } from './useGameActions'

export function useGameFlow() {
  const state = useGameState()
  const userDescription = ref('')
  const validation = useGameValidation(userDescription)
  const actions = useGameActions(state)

  onMounted(() => {
    state.checkForExistingGame()
  })

  return {
    // State
    ...state,

    // Validation
    userDescription,
    ...validation,

    // Actions
    ...actions,
  }
}

// Re-export for convenience
export { useGameState } from './useGameState'
export { useGameValidation } from './useGameValidation'
export { useGameActions } from './useGameActions'
