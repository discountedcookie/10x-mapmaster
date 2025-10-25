import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { useGameStore } from '@/stores/game'
import { usePlaces, type NominatimPlace } from '@/composables/usePlaces'
import type { useGameState } from './useGameState'

export function useGameActions(state: ReturnType<typeof useGameState>) {
  const router = useRouter()
  const gameStore = useGameStore()
  const placesStore = usePlaces()
  const { extractDescriptors, enrichDescriptors } = placesStore
  const { t } = useI18n()

  const saving = ref(false)

  async function startGame(description: string) {
    try {
      await gameStore.startNewGame(description.trim())
      state.gameStarted.value = true
    }
    catch (error) {
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

  async function answerQuestion(answer: boolean) {
    await gameStore.answerQuestion(answer)
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
    }
    catch (error) {
      console.error('Failed to save game:', error)
      toast.error(t('game.toast.save_game_failed_title'), {
        description: t('game.toast.save_game_failed_body'),
      })
    }
    finally {
      saving.value = false
    }
  }

  function handleIncorrectGuess() {
    gameStore.rejectGuessAndContinue()

    if (gameStore.isGameComplete && !gameStore.gameResult) {
      state.showPlaceSearch.value = true
    }
  }

  async function selectPlace(nominatimPlace: NominatimPlace) {
    try {
      saving.value = true
      const lat = Number.parseFloat(nominatimPlace.lat)
      const lng = Number.parseFloat(nominatimPlace.lon)

      let place = await gameStore.checkPlaceExists(lat, lng)
      const isNewPlace = !place

      if (!place) {
        const descriptors = extractDescriptors(nominatimPlace)
        const enrichedDescriptors = await enrichDescriptors(lat, lng, descriptors)

        place = await gameStore.saveNewPlace(
          nominatimPlace.display_name,
          lat,
          lng,
          enrichedDescriptors,
        )
      }

      await gameStore.finalizeGameSession(place, false, isNewPlace)
      toast.success(t('game.toast.place_saved_title'), {
        description: t('game.toast.place_saved_body'),
      })
      state.showPlaceSearch.value = false
      playAgain()
    }
    catch (error) {
      console.error('Failed to save place:', error)
      toast.error(t('game.toast.save_place_failed_title'), {
        description: t('game.toast.save_place_failed_body'),
      })
    }
    finally {
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