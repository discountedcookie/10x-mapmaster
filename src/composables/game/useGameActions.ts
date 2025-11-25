import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { useGameStore } from '@/stores/game'
import type { NominatimPlace } from '@/composables/usePlaces'
import type { useGameState } from './useGameState'

export function useGameActions(state: ReturnType<typeof useGameState>) {
  const router = useRouter()
  const gameStore = useGameStore()
  const { t, locale } = useI18n()

  const saving = ref(false)

  async function startGame(description: string) {
    try {
      await gameStore.startNewGame(description.trim(), locale.value)
      state.gameStarted.value = true
    } catch (error) {
      console.error('Failed to start game:', error)
      toast.error(t('game.toast.start_game_failed_title'), {
        description: t('game.toast.start_game_failed_body'),
      })
    }
  }

  function resumeGame() {
    state.showResumeDialog.value = false
    state.gameStarted.value = true
  }

  function startFreshGame() {
    state.showResumeDialog.value = false
    gameStore.resetGame()
    state.gameStarted.value = false
  }

  async function answerQuestion() {
    await gameStore.submitAnswer('question_answer')
  }

  async function handleCorrectGuess() {
    const result = gameStore.gameResult
    if (!result) return

    try {
      saving.value = true
      await gameStore.finalizeGameSession(result as any, true)
      toast.success(t('game.toast.game_saved_title'), {
        description: t('game.toast.game_saved_body'),
      })
      playAgain()
    } catch (error) {
      console.error('Failed to save game:', error)
      toast.error(t('game.toast.save_game_failed_title'), {
        description: t('game.toast.save_game_failed_body'),
      })
    } finally {
      saving.value = false
    }
  }

  async function handleIncorrectGuess() {
    // This function is deprecated - handled by playTurn now
    console.warn('handleIncorrectGuess is deprecated')
  }

  async function selectPlace(_nominatimPlace: NominatimPlace) {
    try {
      saving.value = true
      // Note: Adding new places should be an admin operation, not frontend
      // Frontend should only work with existing places from database
      toast.error(t('game.toast.save_place_failed_title'), {
        description: 'New places must be added by administrators',
      })
    } catch (error) {
      console.error('Failed to select place:', error)
    } finally {
      saving.value = false
    }
  }

  function playAgain() {
    gameStore.resetGame()
    state.gameStarted.value = false
    state.showPlaceSearch.value = false
  }

  function goHome() {
    router.push('/')
  }

  return {
    saving,
    startGame,
    resumeGame,
    startFreshGame,
    answerQuestion,
    handleCorrectGuess,
    handleIncorrectGuess,
    selectPlace,
    playAgain,
    goHome,
  }
}
