<script setup lang="ts">
import { computed, watchEffect, onUnmounted, unref } from 'vue'
import { useGameFlow } from '@/composables/game'
import { useGameStore, MAX_QUESTIONS } from '@/stores/game'
import MapMarker from '@/components/map/MapMarker.vue'
import GameStartScreen from '@/components/game/GameStartScreen.vue'
import GameResumeDialog from '@/components/game/GameResumeDialog.vue'
import GameLoadingOverlay from '@/components/game/GameLoadingOverlay.vue'
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'
import GameResultCard from '@/components/game/GameResultCard.vue'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import { useMapMarkers } from '@/composables/map/useMapMarkers'
import { useMapState } from '@/composables/map/useMapState'

const gameStore = useGameStore()
const gameFlow = useGameFlow()
const { setMapState, clearMapState } = useMapState()

// Computed for current state value
const currentGameState = computed(() => unref(gameFlow.gameState))

// Compute markers for game mode
const { markerNodes, bounds } = useMapMarkers({
  data: computed(() => gameStore.topCandidates),
  markerComponent: MapMarker,
  computeMarker: (candidate) => ({
    id: `game-${candidate.id}`,
    coordinates: [candidate.lng!, candidate.lat!] as [number, number],
    name: candidate.name,
    backgroundColor: '#ef4444',
    opacity: 0.4 + (candidate.composite_confidence * 0.6),
    similarity: candidate.composite_confidence,
    gameCount: undefined,
  }),
  boundsOptions: {
    padding: 0.25,
  }
})

// Update map state when game markers change
watchEffect(() => {
  setMapState(bounds.value, markerNodes.value)
})

// Clear map state when component unmounts
onUnmounted(() => {
  clearMapState()
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
        :confidence="gameStore.confidence"
        :top-candidates="gameStore.topCandidates.map(candidate => ({
          name: candidate.name,
          confidence: candidate.composite_confidence
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
