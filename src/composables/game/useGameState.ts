import { ref, computed } from 'vue'
import { useGameStore } from '@/stores/game'

export type GameState = 'idle' | 'resumeDialog' | 'start' | 'question' | 'result' | 'placeSearch'

export function useGameState() {
  const gameStore = useGameStore()

  const gameStarted = ref(false)
  const showResumeDialog = ref(false)
  const showPlaceSearch = ref(false)

  const hasExistingGame = computed(() => {
    return gameStore.topCandidates.length > 0 || gameStore.questionCount > 0
  })

  const gameState = computed((): GameState => {
    if (showResumeDialog.value) return 'resumeDialog'
    if (!gameStarted.value) return 'start'
    if (showPlaceSearch.value) return 'placeSearch'
    if (gameStore.isGameComplete) return 'result'
    if (gameStore.currentQuestion) return 'question'
    return 'idle'
  })

  function checkForExistingGame() {
    if (hasExistingGame.value && !gameStarted.value) {
      showResumeDialog.value = true
    }
  }

  return {
    gameStarted,
    showResumeDialog,
    showPlaceSearch,
    hasExistingGame,
    gameState,
    checkForExistingGame,
  }
}