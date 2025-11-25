<script setup lang="ts">
import { ref, watch, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useGameStore } from '@/stores/game'
import { useMapState } from '@/composables/map/useMapState'
import GameQuestion from '@/components/game/GameQuestion.vue'
import GameGuess from '@/components/game/GameGuess.vue'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import type { NominatimPlace } from '@/composables/usePlaces'

const route = useRoute()
const router = useRouter()
const gameStore = useGameStore()
const { setCandidates } = useMapState()
const loadError = ref<string | null>(null)

// Watch candidates and update map state
watch(
  () => gameStore.candidates,
  (candidates) => {
    setCandidates(candidates)
  },
  { immediate: true }
)

// When game is won, fetch correct place and show only that on map
watch(
  () => gameStore.isWon,
  async (isWon) => {
    if (isWon) {
      await gameStore.fetchCorrectPlace()
      // Set map to show only the correct place
      if (gameStore.correctPlace) {
        setCandidates([gameStore.correctPlace])
      }
    }
  },
  { immediate: true }
)

// Get current question/guess from messages (last system message)
const currentMessage = computed(() => {
  const messages = gameStore.gameState?.messages || []
  // Find the last system message (question or guess)
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i]?.role === 'system') {
      return messages[i]
    }
  }
  return null
})

const isQuestion = computed(() => currentMessage.value?.type === 'question')
const isGuess = computed(() => currentMessage.value?.type === 'guess')

// Load game state on mount
onMounted(async () => {
  const sessionId = route.params.sessionId as string

  // Validate session ID format (UUID)
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!sessionId || !uuidRegex.test(sessionId)) {
    loadError.value = 'Invalid session ID'
    await router.push('/')
    return
  }

  // If game store already has this session loaded, skip
  if (gameStore.gameSessionId === sessionId && gameStore.gameState) {
    return
  }

  try {
    // Set the session ID and load game state
    gameStore.gameSessionId = sessionId
    await gameStore.getGameState()
  } catch (error) {
    console.error('Failed to load game:', error)
    loadError.value = error instanceof Error ? error.message : 'Failed to load game'
    // Redirect to home after a delay
    setTimeout(() => {
      router.push('/')
    }, 2000)
  }
})

async function handleAnswer(answer: boolean) {
  try {
    await gameStore.answerQuestion(answer)
  } catch (error) {
    console.error('Failed to answer:', error)
  }
}

async function handlePlaceSubmit(place: NominatimPlace) {
  try {
    await gameStore.submitActualPlace(
      place.display_name,
      parseFloat(place.lat),
      parseFloat(place.lon),
      place.place_id.toString()
    )
    // After successful submission, redirect to home
    router.push('/')
  } catch (error) {
    console.error('Failed to submit place:', error)
  }
}
</script>

<template>
  <div class="relative flex justify-center items-end h-full pb-4 px-4 pointer-events-none">
    <!-- Loading state -->
    <Card
      v-if="gameStore.loading && !gameStore.gameState"
      class="w-full md:max-w-md pointer-events-auto"
    >
      <CardContent class="py-8">
        <p class="text-center text-muted-foreground">Loading game...</p>
      </CardContent>
    </Card>

    <!-- Error state -->
    <Card v-else-if="loadError" class="w-full md:max-w-md pointer-events-auto">
      <CardContent class="py-8">
        <p class="text-center text-destructive">{{ loadError }}</p>
        <p class="text-center text-muted-foreground text-sm mt-2">Redirecting to home...</p>
      </CardContent>
    </Card>

    <!-- Game loaded -->
    <Card v-else-if="gameStore.gameState" class="w-full md:max-w-md pointer-events-auto">
      <CardHeader>
        <CardTitle class="text-center">
          {{ gameStore.gameState.description }}
        </CardTitle>
      </CardHeader>
      <CardContent class="space-y-4">
        <!-- Game won -->
        <div v-if="gameStore.isWon" class="text-center space-y-4">
          <p class="text-2xl">Too easy!</p>
          <p class="text-muted-foreground">
            Guessed in {{ gameStore.gameState.questionCount || 1 }} question{{
              (gameStore.gameState.questionCount || 1) === 1 ? '' : 's'
            }}
          </p>
          <Button class="w-full" @click="router.push('/')">New Game</Button>
        </div>

        <!-- Game ended (needs submission) -->
        <div v-else-if="gameStore.isNeedsSubmission" class="space-y-4">
          <div class="text-center space-y-2">
            <p class="text-xl font-semibold">I give up!</p>
            <p class="text-muted-foreground">Help me learn - what place were you thinking of?</p>
          </div>

          <!-- Inline place search -->
          <GamePlaceSearch @select="handlePlaceSubmit" @cancel="router.push('/')" />
        </div>

        <!-- Active game: Question -->
        <GameQuestion
          v-else-if="isQuestion && currentMessage"
          :question="currentMessage.text"
          :loading="gameStore.loading"
          @answer="handleAnswer"
        />

        <!-- Active game: Guess -->
        <GameGuess
          v-else-if="isGuess && currentMessage"
          :guess-text="currentMessage.text"
          :loading="gameStore.loading"
          @answer="handleAnswer"
        />
      </CardContent>
    </Card>
  </div>
</template>
