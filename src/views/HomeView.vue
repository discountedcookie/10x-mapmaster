<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useGameStore } from '@/stores/game'
import { usePlaces, type Place } from '@/composables/usePlaces'
import { useAutoRotation } from '@/composables/map/useAutoRotation'
import { useMapCamera, MAP_KEY } from '@/composables/map/useMapCamera'
import { useMapLayersStore } from '@/stores/mapLayers'
import PlacesLayer from '@/components/map/PlacesLayer.vue'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const router = useRouter()
const { locale } = useI18n()
const gameStore = useGameStore()
const placesStore = usePlaces()
const mapLayersStore = useMapLayersStore()
const camera = useMapCamera()

// Auto-rotation for home view - travels around places
const rotation = useAutoRotation({ flyDuration: 6000, pauseBetween: 5000, viewZoom: 5 })

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
  (places: any[]) => {
    const validPlaces = places.filter((p: any) => p.lng != null && p.lat != null)

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
  rotation.stop()
  placesStore.unsubscribeRealtime()
})

// Handle start game
async function handleStartGame() {
  if (!description.value.trim()) return

  try {
    // Stop rotation before navigating away
    rotation.stop()

    await gameStore.startNewGame(description.value, locale.value)

    // Redirect to game view with session ID
    if (gameStore.gameSessionId) {
      await router.push(`/game/${gameStore.gameSessionId}`)
    }
  } catch (error) {
    console.error('Failed to start game:', error)
    // Restart rotation if game start failed
    const validPlaces = placesStore.places.filter((p: any) => p.lng != null && p.lat != null)
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
        <CardTitle class="text-center">Describe a place</CardTitle>
      </CardHeader>
      <CardContent class="space-y-4">
        <Input
          v-model="description"
          placeholder="e.g., A famous tower in Paris"
          @keyup.enter="handleStartGame"
        />
        <Button
          class="w-full"
          :disabled="!description.trim() || gameStore.loading"
          @click="handleStartGame"
        >
          {{ gameStore.loading ? 'Starting...' : 'Start Game' }}
        </Button>
      </CardContent>
    </Card>
  </div>
</template>
