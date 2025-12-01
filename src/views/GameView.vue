<script setup lang="ts">
import { ref, watch, computed, onMounted, type Component } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Card } from '@/components/ui/card'
import { logger } from '@/lib/logger'
import { useGameSessionStore } from '@/stores/gameSession'
import { useGameMap } from '@/composables/game/useGameMap'
import GameLoading from '@/components/game/states/GameLoading.vue'
import GameError from '@/components/game/states/GameError.vue'
import GameActive from '@/components/game/states/GameActive.vue'
import GameWon from '@/components/game/states/GameWon.vue'
import GameSubmission from '@/components/game/states/GameSubmission.vue'
import GameSubmissionPending from '@/components/game/states/GameSubmissionPending.vue'

const route = useRoute()
const router = useRouter()
const gameSessionStore = useGameSessionStore()
const { displayCandidates, hideCircles, registerCandidatesLayer } = useGameMap()

const loadError = ref<string | undefined>()
const hoveredPlaceId = ref<string | undefined>()

// State view - returns component and its props together
type StateView = { component: Component; props: Record<string, unknown> }

const stateView = computed<StateView | null>(() => {
  const title = gameSessionStore.session?.description ?? undefined

  if (loadError.value) {
    return { component: GameError, props: { error: loadError.value } }
  }

  if (gameSessionStore.loading && !gameSessionStore.session) {
    return { component: GameLoading, props: {} }
  }

  if (!gameSessionStore.session) {
    return null
  }

  if (gameSessionStore.isWon) {
    return { component: GameWon, props: { title } }
  }
  if (gameSessionStore.isSubmissionPending) {
    return { component: GameSubmissionPending, props: { title } }
  }
  if (gameSessionStore.isNeedsSubmission) {
    return { component: GameSubmission, props: {} }
  }
  if (gameSessionStore.isGameActive) {
    return { component: GameActive, props: { title } }
  }

  return null
})

// Register candidates layer when candidates or display settings change
watch(
  [() => displayCandidates.value, hideCircles, hoveredPlaceId],
  () => {
    registerCandidatesLayer(hoveredPlaceId.value)
  },
  { immediate: true }
)

onMounted(async () => {
  const sessionId = route.params.sessionId as string

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!sessionId || !uuidRegex.test(sessionId)) {
    loadError.value = 'Invalid session ID'
    await router.push('/')
    return
  }

  if (gameSessionStore.session?.session_id === sessionId) {
    return
  }

  try {
    await gameSessionStore.refresh(sessionId)
  } catch (error) {
    logger.error('Failed to load game:', error)
    loadError.value = error instanceof Error ? error.message : 'Failed to load game'
    setTimeout(() => {
      router.push('/')
    }, 2000)
  }
})
</script>

<template>
  <!-- UI overlay -->
  <div class="relative flex justify-center items-end h-full pb-4 px-4 pointer-events-none">
    <!-- Card wrapper with pointer-events-auto for interaction -->
    <Card v-if="stateView" class="w-full md:max-w-md pointer-events-auto">
      <component :is="stateView.component" v-bind="stateView.props" />
    </Card>
  </div>
</template>
