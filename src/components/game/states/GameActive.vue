<script setup lang="ts">
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { logger } from '@/lib/logger'
import { useGameSessionStore } from '@/stores/gameSession'
import { useGameMap } from '@/composables/game/useGameMap'
import { calculateBounds } from '@/lib/map-utils'
import GameQuestion from '@/components/game/GameQuestion.vue'
import GameGuess from '@/components/game/GameGuess.vue'

const { t } = useI18n({ useScope: 'global' })

interface Properties {
  title?: string
}

interface QuestionJson {
  id: string | null
  text: string | null
}

interface GuessJson {
  place_id: string | null
  place_name: string | null
}

defineProps<Properties>()

const gameSessionStore = useGameSessionStore()
const { camera, displayCandidates } = useGameMap()

// Narrow session JSON payload to shallow frontend-friendly shapes
const session = computed(
  () =>
    gameSessionStore.session as {
      question: QuestionJson | null
      guess: GuessJson | null
    } | null
)

const question = computed<QuestionJson | null>(() => {
  return session.value?.question ?? null
})

const guess = computed<GuessJson | null>(() => {
  return session.value?.guess ?? null
})

const questionText = computed(() => question.value?.text ?? '')

const guessText = computed(() => {
   const value = guess.value
   if (!value?.place_name) return ''
   return t('game.guess', { place: value.place_name })
 })

const isQuestion = computed(() => !!question.value?.text && !guess.value)
const isGuess = computed(() => !!guess.value?.place_name)

async function fitBoundsToCandidates() {
  const candidates = displayCandidates.value
  if (candidates.length > 0 && camera && camera.isLoaded.value) {
    const bounds = calculateBounds(candidates)
    await camera.fitBounds(bounds, {
      padding: 100,
      duration: 1000,
      maxZoom: 12,
    })
  }
}

if (camera) {
  watch(() => displayCandidates.value, fitBoundsToCandidates, { immediate: true })

  watch(
    () => camera.isLoaded.value,
    (isLoaded) => {
      if (isLoaded) {
        fitBoundsToCandidates()
      }
    },
    { immediate: true }
  )
}

async function handleAnswer(answer: boolean) {
  try {
    await gameSessionStore.answer(answer)
  } catch (error) {
    logger.error('Failed to answer:', error)
  }
}
</script>

<template>
  <div>
    <CardHeader v-if="title">
      <CardTitle class="text-center">
        {{ title }}
      </CardTitle>
    </CardHeader>
    <CardContent class="space-y-4">
      <GameQuestion
        v-if="isQuestion && questionText"
        :question="questionText"
        :loading="gameSessionStore.loading"
        @answer="handleAnswer"
      />

      <GameGuess
        v-else-if="isGuess && guessText"
        :guess-text="guessText"
        :loading="gameSessionStore.loading"
        @answer="handleAnswer"
      />
    </CardContent>
  </div>
</template>
