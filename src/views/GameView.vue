<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useGameStore, MAX_QUESTIONS } from '@/stores/game'
import { usePlaces, type NominatimPlace } from '@/composables/usePlaces'
import QuestionCard from '@/components/game/QuestionCard.vue'
import ResultCard from '@/components/game/ResultCard.vue'
import PlaceSearch from '@/components/game/PlaceSearch.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'

const router = useRouter()
const authStore = useAuthStore()
const gameStore = useGameStore()
const placesStore = usePlaces()
const { extractDescriptors, enrichDescriptors } = placesStore
const { t } = useI18n()

const showPlaceSearch = ref(false)
const gameStarted = ref(false)
const saving = ref(false)
const userDescription = ref('')

// Input validation constants
const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500

const descriptionLength = computed(() => userDescription.value.length)
const isDescriptionValid = computed(() => {
  const trimmed = userDescription.value.trim()
  return trimmed.length >= MIN_DESCRIPTION_LENGTH && trimmed.length <= MAX_DESCRIPTION_LENGTH
})
const validationMessage = computed(() => {
  const trimmed = userDescription.value.trim()
  if (trimmed.length === 0) return ''
  if (trimmed.length < MIN_DESCRIPTION_LENGTH) {
    return t('game.validation.min_length', { length: MIN_DESCRIPTION_LENGTH, current: trimmed.length })
  }
  if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
    return t('game.validation.max_length', { length: MAX_DESCRIPTION_LENGTH })
  }
  return ''
})

async function startGame() {
  if (!isDescriptionValid.value) {
    toast.error(t('game.toast.invalid_description_title'), {
      description: validationMessage.value || t('game.toast.invalid_description_body'),
    })
    return
  }

  try {
    await gameStore.startNewGame(userDescription.value.trim())
    gameStarted.value = true
  }
  catch (error) {
    console.error('Failed to start game:', error)
    toast.error(t('game.toast.start_game_failed_title'), {
      description: t('game.toast.start_game_failed_body'),
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

      // Enrich descriptors with elevation/height data
      const enrichedDescriptors = await enrichDescriptors(lat, lng, descriptors)

      place = await gameStore.saveNewPlace(
        nominatimPlace.display_name,
        lat,
        lng,
        enrichedDescriptors,
      )
    }

    // Save game session (pass isNewPlace to skip redundant embedding update)
    await gameStore.finalizeGameSession(place, false, isNewPlace)
    toast.success(t('game.toast.place_saved_title'), {
      description: t('game.toast.place_saved_body'),
    })
    showPlaceSearch.value = false
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
  gameStarted.value = false
  showPlaceSearch.value = false
  userDescription.value = ''
}

function goHome() {
  router.push('/')
}
</script>

<template>
  <!-- Game UI - Centered Cards -->
  <div class="absolute inset-0 flex items-center justify-center p-4 pointer-events-none">
    <div class="pointer-events-auto max-w-2xl w-full max-h-[calc(100vh-6rem)]">
      <!-- Start Screen -->
      <Card
        v-if="!gameStarted"
        class="w-full animate-slide-up-fade"
        style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
      >
        <CardHeader class="text-center space-y-3">
          <CardTitle class="text-4xl font-bold flex items-center justify-center gap-3">
            <Icon
              icon="radix-icons:pencil-1"
              class="h-10 w-10 text-primary"
            />
            {{ t('game.describe_place_title') }}
          </CardTitle>
          <CardDescription class="text-xl">
            {{ t('game.describe_place_description') }}
          </CardDescription>
        </CardHeader>
        <CardContent class="flex flex-col gap-4">
          <div class="space-y-2">
            <Textarea
              v-model="userDescription"
              :placeholder="t('game.description_placeholder')"
              rows="4"
              class="resize-none"
              :maxlength="MAX_DESCRIPTION_LENGTH"
            />
            <div class="flex justify-between items-center text-sm gap-2">
              <p
                v-if="validationMessage"
                class="text-destructive flex-1"
              >
                {{ validationMessage }}
              </p>
              <p
                v-else
                class="text-muted-foreground flex-1"
              >
                {{ MIN_DESCRIPTION_LENGTH }}-{{ MAX_DESCRIPTION_LENGTH }} {{ t('common.characters') }}
              </p>
              <p
                class="text-muted-foreground whitespace-nowrap"
                :class="{ 'text-destructive': descriptionLength > MAX_DESCRIPTION_LENGTH }"
              >
                {{ descriptionLength }}/{{ MAX_DESCRIPTION_LENGTH }}
              </p>
            </div>
          </div>
          <Button
            size="lg"
            class="transition-playful"
            :disabled="!isDescriptionValid || gameStore.loading"
            @click="startGame"
          >
            <Icon
              v-if="!gameStore.loading"
              icon="radix-icons:play"
              class="h-5 w-5 mr-2"
            />
            {{ gameStore.loading ? t('game.starting') : t('game.start_game') }}
          </Button>
          <Button
            size="lg"
            variant="outline"
            class="transition-playful"
            @click="goHome"
          >
            <Icon
              icon="radix-icons:home"
              class="h-5 w-5 mr-2"
            />
            {{ t('common.back_to_home') }}
          </Button>
        </CardContent>
      </Card>

      <!-- Question Phase -->
      <QuestionCard
        v-else-if="!gameStore.isGameComplete && gameStore.currentQuestion"
        :question="gameStore.currentQuestion.text"
        :question-number="gameStore.questionCount + 1"
        :total-questions="MAX_QUESTIONS"
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

  <!-- Loading Overlay (Full Screen) -->
  <div
    v-if="gameStore.loading && !gameStarted"
    class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 backdrop-blur-sm pointer-events-auto z-50"
  >
    <Card class="max-w-md mx-4">
      <CardContent class="pt-6 pb-6 flex flex-col items-center gap-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
        <div class="text-center space-y-1">
          <p class="font-semibold text-lg">
            {{ t('game.loading_overlay.analyzing_description') }}
          </p>
          <p class="text-sm text-muted-foreground">
            {{ t('game.loading_overlay.finding_places') }}
          </p>
        </div>
      </CardContent>
    </Card>
  </div>

  <!-- Error message -->
  <div
    v-if="gameStore.error"
    class="fixed top-20 left-1/2 -translate-x-1/2 bg-destructive text-destructive-foreground px-4 py-2 rounded-md pointer-events-auto z-50"
  >
    {{ gameStore.error || t('common.error') }}
  </div>
</template>
