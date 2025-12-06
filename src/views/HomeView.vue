<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { logger } from '@/lib/logger'
import { useGameSessionStore } from '@/stores/gameSession'
import { usePlaces } from '@/composables/usePlaces'
import { useAutoRotation } from '@/composables/map/useAutoRotation'
import { useMapCamera, MAP_KEY } from '@/composables/map/useMapCamera'
import { useMapLayersStore } from '@/stores/mapLayers'
import PlacesLayer from '@/components/map/PlacesLayer.vue'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const router = useRouter()
const { locale, t } = useI18n({ useScope: 'global' })
const gameSessionStore = useGameSessionStore()
const placesStore = usePlaces()
const mapLayersStore = useMapLayersStore()
const camera = useMapCamera()

// Single constant for rotation timing (used for both pauseBetween and resume delay)
const ROTATION_DELAY = 5000

// Smart resume: reset timeout on EVERY user interaction
let resumeTimeoutId: ReturnType<typeof setTimeout> | undefined

function scheduleResume() {
  // Clear any existing timeout
  if (resumeTimeoutId) {
    clearTimeout(resumeTimeoutId)
  }
  // Schedule resume after delay
  resumeTimeoutId = setTimeout(() => {
    rotation.resume()
    resumeTimeoutId = undefined
  }, ROTATION_DELAY)
}

// Auto-rotation for home view - travels around places
const rotation = useAutoRotation({
  flyDuration: 6000,
  pauseBetween: ROTATION_DELAY,
  viewZoom: 5,
  onInteraction: scheduleResume, // Reset timeout on EVERY interaction
})

// Description input
const description = ref('')

// Track if rotation has been started
let rotationStarted = false

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Update rotation and layers when places load
watch(
  () => placesStore.places,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (places: any[]) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const validPlaces = places.filter((p: any) => p.lng != undefined && p.lat != undefined)

    // Update layer props with new places data
    mapLayersStore.setLayers([
      {
        key: 'places',
        component: PlacesLayer,
        props: {
          places: placesStore.places,
          mapKey: MAP_KEY,
        },
      },
    ])

    // If we have places, update and start rotation if not already started
    if (validPlaces.length > 0) {
      rotation.setPlaces(validPlaces as { lng: number; lat: number }[])
      if (!rotationStarted) {
        rotationStarted = true
        // Detect if we're on a fresh page load vs navigating from another view
        // Fresh load: camera at default position [0, 20] zoom ~2
        const c = camera.center.value
        const z = camera.zoom.value
        const isDefaultPosition = Math.abs(c.lng) < 1 && Math.abs(c.lat - 20) < 1 && z < 3
        // 'initial' for fresh page load (cinematic intro), 'transition' for view transitions
        rotation.start(isDefaultPosition ? 'initial' : 'transition')
      }
    }
  },
  { immediate: true }
)

// Clean up on unmount
onUnmounted(() => {
  if (resumeTimeoutId) {
    clearTimeout(resumeTimeoutId)
    resumeTimeoutId = undefined
  }
  rotation.stop()
})

// Handle start game
async function handleStartGame() {
  if (!description.value.trim()) return

  try {
    rotation.stop()

    await gameSessionStore.startNewGame(description.value, locale.value)

    const id = gameSessionStore.session?.session_id ?? null
    if (id) {
      await router.push(`/game/${id}`)
    }
  } catch (error) {
    logger.error('Failed to start game:', error)

    type SimplePlace = { lng: number | null; lat: number | null }
    const validPlaces = (placesStore.places as SimplePlace[]).filter(
      (p) => p.lng != null && p.lat != null
    )
    if (validPlaces.length > 0) {
      rotation.setPlaces(validPlaces as { lng: number; lat: number }[])
      rotation.start('transition')
    }
  }
}
</script>

<template>
  <!-- UI overlay -->
  <div class="relative flex justify-center items-end h-full pb-4 px-4 pointer-events-none">
    <Card class="w-full md:max-w-md pointer-events-auto">
      <CardHeader>
        <CardTitle class="text-center">{{ t('game.describe_place_title') }}</CardTitle>
      </CardHeader>
      <CardContent class="space-y-4">
        <Input
          v-model="description"
          :placeholder="t('game.description_placeholder')"
          @keyup.enter="handleStartGame"
        />
        <Button
          class="w-full"
          :disabled="!description.trim() || gameSessionStore.loading"
          @click="handleStartGame"
        >
          {{ gameSessionStore.loading ? t('game.starting') : t('game.start_game') }}
        </Button>
      </CardContent>
    </Card>
  </div>
</template>
