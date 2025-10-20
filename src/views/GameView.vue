<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import { useGameStore } from '@/stores/game'
import { useNominatim, type NominatimPlace } from '@/composables/useNominatim'
import MapView from '@/components/map/MapView.vue'
import AuthModal from '@/components/AuthModal.vue'
import QuestionCard from '@/components/game/QuestionCard.vue'
import ResultCard from '@/components/game/ResultCard.vue'
import PlaceSearch from '@/components/game/PlaceSearch.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'

const router = useRouter()
const authStore = useAuthStore()
const gameStore = useGameStore()
const { extractDescriptors } = useNominatim()

const showAuthModal = ref(false)
const showPlaceSearch = ref(false)
const gameStarted = ref(false)
const saving = ref(false)
const userDescription = ref('')

// Input validation constants
const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500

const mapCandidates = computed(() => {
  return gameStore.topCandidates.map(place => ({
    lat: place.lat,
    lng: place.lng,
    name: place.name,
    similarity: place.composite_confidence,
  }))
})

const descriptionLength = computed(() => userDescription.value.length)
const isDescriptionValid = computed(() => {
  const trimmed = userDescription.value.trim()
  return trimmed.length >= MIN_DESCRIPTION_LENGTH && trimmed.length <= MAX_DESCRIPTION_LENGTH
})
const validationMessage = computed(() => {
  const trimmed = userDescription.value.trim()
  if (trimmed.length === 0) return ''
  if (trimmed.length < MIN_DESCRIPTION_LENGTH) {
    return `At least ${MIN_DESCRIPTION_LENGTH} characters required (${trimmed.length}/${MIN_DESCRIPTION_LENGTH})`
  }
  if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
    return `Maximum ${MAX_DESCRIPTION_LENGTH} characters exceeded`
  }
  return ''
})

onMounted(async () => {
  if (!authStore.isAuthenticated) {
    showAuthModal.value = true
  }
})

async function startGame() {
  if (!isDescriptionValid.value) {
    toast.error('Invalid description', {
      description: validationMessage.value || 'Please provide a valid description.',
    })
    return
  }

  try {
    await gameStore.startNewGame(userDescription.value.trim())
    gameStarted.value = true
  }
  catch (error) {
    console.error('Failed to start game:', error)
    toast.error('Failed to start game', {
      description: 'Please try again or check your connection.',
    })
  }
}

async function handleAnswer(answer: boolean) {
  await gameStore.answerQuestion(answer)
}

async function handleCorrectGuess() {
  const result = gameStore.gameResult
  if (!result)
    return

  try {
    saving.value = true
    // Cast to remove type recursion issues
    await gameStore.saveGameSession(result as any, true)
    toast.success('Game saved!', {
      description: 'Great job! Your game has been recorded.',
    })
    playAgain()
  }
  catch (error) {
    console.error('Failed to save game:', error)
    toast.error('Failed to save game', {
      description: 'Please try again.',
    })
  }
  finally {
    saving.value = false
  }
}

function handleIncorrectGuess() {
  // Remove the incorrect guess from candidates and continue with questions
  gameStore.rejectGuessAndContinue()

  // If there are still candidates or questions to ask, continue playing
  // Otherwise, show place search
  if (gameStore.isGameComplete && !gameStore.gameResult) {
    // No more candidates and no result means we couldn't find it
    showPlaceSearch.value = true
  }
  // Otherwise the game will automatically show the next question or next guess
}

async function handlePlaceSelect(nominatimPlace: NominatimPlace) {
  try {
    saving.value = true
    const lat = Number.parseFloat(nominatimPlace.lat)
    const lng = Number.parseFloat(nominatimPlace.lon)

    // Check if place exists
    let place = await gameStore.checkPlaceExists(lat, lng)
    const isNewPlace = !place

    // If not, create it
    if (!place) {
      const descriptors = extractDescriptors(nominatimPlace)
      place = await gameStore.saveNewPlace(
        nominatimPlace.display_name,
        lat,
        lng,
        descriptors,
      )
    }

    // Save game session (pass isNewPlace to skip redundant embedding update)
    await gameStore.saveGameSession(place, false, isNewPlace)
    toast.success('Place saved!', {
      description: 'Thanks! We\'ve added this place for future games.',
    })
    showPlaceSearch.value = false
    playAgain()
  }
  catch (error) {
    console.error('Failed to save place:', error)
    toast.error('Failed to save place', {
      description: 'Please try again.',
    })
  }
  finally {
    saving.value = false
  }
}

function playAgain() {
  gameStore.resetGame()
  gameStarted.value = false
  showPlaceSearch.value = false
  userDescription.value = ''
}

function goHome() {
  router.push('/')
}
</script>

<template>
  <div class="relative h-screen w-screen">
    <!-- Map Background -->
    <MapView :candidates="mapCandidates" />

    <!-- Auth Modal -->
    <AuthModal v-if="showAuthModal && !authStore.isAuthenticated" />

    <!-- Game UI Overlay -->
    <div
      v-if="authStore.isAuthenticated"
      class="absolute inset-0 flex flex-col items-center justify-center p-4 pointer-events-none"
    >
      <div class="pointer-events-auto">
        <!-- Start Screen -->
        <Card
          v-if="!gameStarted"
          class="w-full max-w-2xl"
        >
          <CardHeader class="text-center">
            <CardTitle class="text-4xl">
              Describe a Place
            </CardTitle>
            <CardDescription class="text-xl">
              Tell us about the place you're thinking of
            </CardDescription>
          </CardHeader>
          <CardContent class="flex flex-col gap-4">
            <div class="space-y-2">
              <Textarea
                v-model="userDescription"
                placeholder="e.g., A famous iron tower in Paris with a lattice structure"
                rows="4"
                class="resize-none"
                :maxlength="MAX_DESCRIPTION_LENGTH"
              />
              <div class="flex justify-between items-center text-sm">
                <p
                  v-if="validationMessage"
                  class="text-destructive"
                >
                  {{ validationMessage }}
                </p>
                <p
                  v-else
                  class="text-muted-foreground"
                >
                  Describe the place you're thinking of ({{ MIN_DESCRIPTION_LENGTH }}-{{ MAX_DESCRIPTION_LENGTH }} characters)
                </p>
                <p
                  class="text-muted-foreground"
                  :class="{ 'text-destructive': descriptionLength > MAX_DESCRIPTION_LENGTH }"
                >
                  {{ descriptionLength }}/{{ MAX_DESCRIPTION_LENGTH }}
                </p>
              </div>
            </div>
            <Button
              size="lg"
              :disabled="!isDescriptionValid || gameStore.loading"
              @click="startGame"
            >
              {{ gameStore.loading ? 'Starting...' : 'Start Game' }}
            </Button>
            <Button
              size="lg"
              variant="outline"
              @click="goHome"
            >
              Back to Home
            </Button>
          </CardContent>
        </Card>

        <!-- Question Phase -->
        <QuestionCard
          v-else-if="!gameStore.isGameComplete && gameStore.currentQuestion"
          :question="gameStore.currentQuestion.text"
          :question-number="gameStore.currentQuestionIndex + 1"
          :total-questions="gameStore.questions.length"
          :candidates-count="gameStore.candidates.length"
          :confidence="gameStore.confidence"
          @answer="handleAnswer"
        />

        <!-- Result Phase -->
        <ResultCard
          v-else-if="gameStore.isGameComplete && !showPlaceSearch"
          :guess="gameStore.gameResult"
          :disabled="saving"
          @correct="handleCorrectGuess"
          @incorrect="handleIncorrectGuess"
          @play-again="playAgain"
        />

        <!-- Place Search -->
        <PlaceSearch
          v-else-if="showPlaceSearch"
          @select="handlePlaceSelect"
          @cancel="showPlaceSearch = false"
        />
      </div>
    </div>

    <!-- Loading Overlay -->
    <div
      v-if="gameStore.loading && !gameStarted"
      class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 backdrop-blur-sm pointer-events-auto z-50"
    >
      <Card class="max-w-md mx-4">
        <CardContent class="pt-6 pb-6 flex flex-col items-center gap-4">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
          <div class="text-center space-y-1">
            <p class="font-semibold text-lg">
              Analyzing your description...
            </p>
            <p class="text-sm text-muted-foreground">
              Finding matching places
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
    <div
      v-if="gameStore.error"
      class="absolute top-4 left-1/2 -translate-x-1/2 bg-destructive text-destructive-foreground px-4 py-2 rounded-md pointer-events-auto"
    >
      {{ gameStore.error }}
    </div>
  </div>
</template>
