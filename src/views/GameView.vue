<script setup lang="ts">
import { computed, watchEffect, unref } from 'vue'
import { useGameFlow } from '@/composables/game'
import { useGameStore, MAX_QUESTIONS, normalizeConfidenceForDisplay } from '@/stores/game'
import GameStartScreen from '@/components/game/GameStartScreen.vue'
import GameResumeDialog from '@/components/game/GameResumeDialog.vue'
import GameLoadingOverlay from '@/components/game/GameLoadingOverlay.vue'
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'
import GameResultCard from '@/components/game/GameResultCard.vue'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import { useMapBounds } from '@/composables/map/useMapBounds'
import { useMapState } from '@/composables/map/useMapState'
import { usePlaces } from '@/composables/usePlaces'

const gameStore = useGameStore()
const gameFlow = useGameFlow()
const placesStore = usePlaces()
const { setMapState } = useMapState()

// Computed for current state value
const currentGameState = computed(() => unref(gameFlow.gameState))

// Compute game candidate markers as places
const gameMarkers = computed(() => {
  return gameStore.topCandidates
    .filter(c => c.lat !== null && c.lng !== null)
    .map(candidate => ({
      id: `game-${candidate.id}`,
      name: candidate.name,
      lat: candidate.lat!,
      lng: candidate.lng!,
      game_count: undefined,
      // Store styling info as extensions
      backgroundColor: '#ef4444',
      opacity: 0.4 + (candidate.composite_confidence * 0.6),
      similarity: candidate.composite_confidence,
    }))
})

// Calculate bounds for game markers
const markerCoordinates = computed(() => {
  return gameMarkers.value
    .filter(m => typeof m.lat === 'number' && typeof m.lng === 'number' && !Number.isNaN(m.lat) && !Number.isNaN(m.lng))
    .map(marker => ({
      coordinates: [marker.lng, marker.lat] as [number, number],
    }))
})

const bounds = useMapBounds(markerCoordinates, 0.25)

// Compute all places for map when game is not active
const allPlaces = computed(() => {
  return placesStore.places.filter(p => p.lat !== null && p.lng !== null)
})

const allPlacesMarkers = computed(() => {
  return allPlaces.value.map(place => ({
    coordinates: [place.lng!, place.lat!] as [number, number],
  }))
})

const allPlacesBounds = useMapBounds(allPlacesMarkers)

// Update map state based on game phase
watchEffect(() => {
  const gameState = currentGameState.value
  const isGameActive = gameState === 'question' || gameState === 'result'

  if (isGameActive) {
    const validMarkers = gameMarkers.value.filter(m =>
      typeof m.lat === 'number' && typeof m.lng === 'number' && !Number.isNaN(m.lat) && !Number.isNaN(m.lng),
    )
    // Show candidate markers when game is actively running
    if (validMarkers.length > 0 && bounds.value && Array.isArray(bounds.value) && bounds.value.length === 2) {
      setMapState(bounds.value, validMarkers as any)
    }
  }
  else {
    // Show all places when game is not active (start, placeSearch, resumeDialog, idle)
    if (allPlaces.value.length > 0 && allPlacesBounds.value) {
      setMapState(allPlacesBounds.value, allPlaces.value)
    }
  }
})
</script>

<template>
  <!-- Game UI - Centered Cards -->
  <div class="absolute inset-0 flex items-center justify-center p-4 pointer-events-none">
    <div class="pointer-events-auto max-w-2xl w-full max-h-[calc(100vh-6rem)]">
      <!-- Resume Game Dialog -->
      <GameResumeDialog
        v-if="currentGameState === 'resumeDialog'"
        :question-count="gameStore.questionCount"
        :max-questions="MAX_QUESTIONS"
        :candidates-count="gameStore.topCandidates.length"
        @resume="gameFlow.resumeGame"
        @start-fresh="gameFlow.startFreshGame"
      />

      <!-- Start Screen -->
      <GameStartScreen
        v-else-if="currentGameState === 'start'"
        :description="unref(gameFlow.userDescription)"
        :validation-message="unref(gameFlow.validationMessage)"
        :description-length="unref(gameFlow.descriptionLength)"
        :is-valid="unref(gameFlow.isDescriptionValid)"
        :loading="gameStore.loading"
        :min-length="gameFlow.MIN_DESCRIPTION_LENGTH"
        :max-length="gameFlow.MAX_DESCRIPTION_LENGTH"
        @update:description="(val) => { gameFlow.userDescription.value = val }"
        @start="gameFlow.startGame(unref(gameFlow.userDescription))"
        @go-home="gameFlow.goHome"
      />

      <!-- Question Phase -->
      <GameQuestionCard
        v-else-if="currentGameState === 'question' && gameStore.currentQuestion"
        :question="gameStore.currentQuestion.text"
        :question-number="gameStore.questionCount + 1"
        :total-questions="MAX_QUESTIONS"
        :candidates-count="gameStore.candidates.length"
        :confidence="gameStore.displayConfidence"
        :top-candidates="gameStore.topCandidates.map(candidate => ({
          name: candidate.name,
          confidence: normalizeConfidenceForDisplay(candidate.composite_confidence)
        }))"
        @answer="gameFlow.answerQuestion"
      />

      <!-- Result Phase -->
      <GameResultCard
        v-else-if="currentGameState === 'result'"
        :guess="gameStore.gameResult"
        :disabled="unref(gameFlow.saving)"
        @correct="gameFlow.handleCorrectGuess"
        @incorrect="gameFlow.handleIncorrectGuess"
        @play-again="gameFlow.playAgain"
      />

      <!-- Place Search -->
      <GamePlaceSearch
        v-else-if="currentGameState === 'placeSearch'"
        @select="gameFlow.selectPlace"
        @cancel="() => { gameFlow.showPlaceSearch.value = false }"
      />
    </div>
  </div>

  <!-- Loading Overlay -->
  <GameLoadingOverlay v-if="gameStore.loading && !unref(gameFlow.gameStarted)" />

  <!-- Error message -->
  <div
    v-if="gameStore.error"
    class="fixed top-20 left-1/2 -translate-x-1/2 bg-destructive text-destructive-foreground px-4 py-2 rounded-md pointer-events-auto z-50"
  >
    {{ gameStore.error }}
  </div>
</template>
