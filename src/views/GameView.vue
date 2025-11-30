<script setup lang="ts">
import { ref, watch, computed, onMounted, onUnmounted, watchEffect } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useGameStore } from '@/stores/game'
import { useMapCamera, MAP_KEY } from '@/composables/map/useMapCamera'
import { useMapLayersStore } from '@/stores/mapLayers'
import GameQuestion from '@/components/game/GameQuestion.vue'
import GameGuess from '@/components/game/GameGuess.vue'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import CandidatesLayer from '@/components/map/CandidatesLayer.vue'
import type { NominatimPlace } from '@/composables/usePlaces'

const route = useRoute()
const router = useRouter()
const gameStore = useGameStore()
const mapLayersStore = useMapLayersStore()
const loadError = ref<string | null>(null)
const hoveredPlaceId = ref<string | null>(null)

const camera = useMapCamera()

// Fit bounds to candidates - helper function
async function fitBoundsToCandidates() {
  const candidates = gameStore.candidates
  if (candidates.length > 0 && camera && camera.isLoaded.value) {
    // Calculate bounds from candidates
    const lngs = candidates.map((c) => c.lng)
    const lats = candidates.map((c) => c.lat)
    const bounds: [[number, number], [number, number]] = [
      [Math.min(...lngs), Math.min(...lats)],
      [Math.max(...lngs), Math.max(...lats)],
    ]

    await camera.fitBounds(bounds, {
      padding: 100,
      duration: 1000,
      maxZoom: 12,
    })
  }
}

// Fit bounds when candidates change
if (camera) {
  watch(() => gameStore.candidates, fitBoundsToCandidates, { immediate: true })

  // Also fit bounds when map loads (for page refresh case)
  watch(
    () => camera.isLoaded.value,
    (isLoaded) => {
      if (isLoaded) {
        fitBoundsToCandidates()
      }
    },
    { immediate: true }
  )

  // When game is won, zoom to correct place with 3D pitch
  watch(
    () => gameStore.isWon,
    async (isWon) => {
      if (isWon) {
        await gameStore.fetchCorrectPlace()
        if (gameStore.correctPlace && camera.isLoaded.value) {
          await camera.flyTo({
            center: [gameStore.correctPlace.lng, gameStore.correctPlace.lat],
            zoom: 14,
            pitch: 55,
            bearing: 0,
            duration: 1500,
          })
        }
      }
    },
    { immediate: true }
  )

  // When place is submitted (pending review), zoom to it with 3D pitch
  watch(
    () => gameStore.isSubmissionPending,
    async (isPending) => {
      if (isPending && gameStore.submittedPlace && camera.isLoaded.value) {
        await camera.flyTo({
          center: [gameStore.submittedPlace.lng, gameStore.submittedPlace.lat],
          zoom: 14,
          pitch: 55,
          bearing: 0,
          duration: 1500,
        })
      }
    },
    { immediate: true }
  )
}

// ===== 3D Extrusion Layer for Win State =====
// Adds extruded building polygon when game is won (like PlaceView)
function setup3DLayer() {
  if (!camera || !gameStore.correctPlace || !camera.map.value) return
  const map = camera.map.value
  const placeData = gameStore.correctPlace as any
  if (!placeData.geometry) return

  const sourceId = 'win-extrusion-source'
  const layerId = 'win-extrusion-layer'

  // Remove existing layer and source if present
  if (map.getLayer(layerId)) {
    map.removeLayer(layerId)
  }
  if (map.getSource(sourceId)) {
    map.removeSource(sourceId)
  }

  // Create GeoJSON source from place geometry
  map.addSource(sourceId, {
    type: 'geojson',
    data: {
      type: 'Feature',
      properties: {},
      geometry: placeData.geometry as any,
    },
  })

  // Add fill-extrusion layer for 3D effect
  map.addLayer({
    id: layerId,
    type: 'fill-extrusion',
    source: sourceId,
    paint: {
      // Complementary orange color to the blue markers
      'fill-extrusion-color': '#fb923c',
      'fill-extrusion-opacity': 0.7,
      // Height based on zoom - taller at higher zoom
      'fill-extrusion-height': [
        'interpolate',
        ['linear'],
        ['zoom'],
        12,
        0,
        14,
        30,
        16,
        60,
        18,
        100,
      ],
      'fill-extrusion-base': 0,
    },
    minzoom: 12,
  })
}

function cleanup3DLayer() {
  if (!camera || !camera.map.value) return
  const map = camera.map.value

  const sourceId = 'win-extrusion-source'
  const layerId = 'win-extrusion-layer'

  if (map.getLayer(layerId)) {
    map.removeLayer(layerId)
  }
  if (map.getSource(sourceId)) {
    map.removeSource(sourceId)
  }
}

// Setup 3D layer when game is won and correct place has geometry
watchEffect(() => {
  if (gameStore.isWon && gameStore.correctPlace && camera?.isLoaded.value && camera?.map.value) {
    // Small delay to ensure flyTo has started
    setTimeout(() => setup3DLayer(), 500)
  }
})

// Cleanup on unmount
onUnmounted(() => {
  cleanup3DLayer()
})

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

// Candidates to show - when won, show only correct place; when searching, show search results; when pending submission, show submitted place
const displayCandidates = computed(() => {
  // Winner state - show correct place
  if (gameStore.isWon && gameStore.correctPlace) {
    return [gameStore.correctPlace]
  }

  // Submission pending - show submitted place as winner
  if (gameStore.isSubmissionPending && gameStore.submittedPlace) {
    return [
      {
        id: 'submitted',
        name: gameStore.submittedPlace.name,
        lat: gameStore.submittedPlace.lat,
        lng: gameStore.submittedPlace.lng,
        confidence: 1,
        description_similarity: 1,
        affirmed_trait_similarity: null,
        denied_trait_similarity: null,
        geographic_distance: null,
      },
    ]
  }

  // During search - show Nominatim results as candidates
  if (gameStore.searchResultPlaces.length > 0) {
    return gameStore.searchResultPlaces.map((p) => ({
      id: p.id,
      name: p.name,
      lat: p.lat,
      lng: p.lng,
      confidence: 0.5, // Neutral confidence for search results
      description_similarity: 0.5,
      affirmed_trait_similarity: null,
      denied_trait_similarity: null,
      geographic_distance: null,
    }))
  }

  return gameStore.candidates
})

// Hide circles when 3D polygon is shown (won game with geometry)
const hideCircles = computed(() => {
  return gameStore.isWon && gameStore.correctPlace && !!(gameStore.correctPlace as any).geometry
})

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

// Register candidates layer when candidates are available
watch(
  [() => displayCandidates.value, hideCircles, hoveredPlaceId],
  ([candidates, shouldHideCircles, highlightedId]) => {
    if (candidates.length > 0) {
      mapLayersStore.setLayers([
        {
          key: 'candidates',
          component: CandidatesLayer,
          props: {
            candidates: candidates,
            mapKey: MAP_KEY,
            hideCircles: shouldHideCircles,
            highlightedId: highlightedId,
          },
        },
      ])
    }
  },
  { immediate: true }
)

async function handleAnswer(answer: boolean) {
  try {
    await gameStore.answerQuestion(answer)
  } catch (error) {
    console.error('Failed to answer:', error)
  }
}

async function handlePlaceSubmit(place: NominatimPlace) {
  try {
    // Format: "{osm_type}/{osm_id}" e.g. "way/5013364"
    const osmId = `${place.osm_type}/${place.osm_id}`

    // Store place data for display (frontend-only)
    gameStore.setSubmittedPlace({
      name: place.display_name,
      lat: parseFloat(place.lat),
      lng: parseFloat(place.lon),
    })

    await gameStore.submitActualPlace(
      place.display_name,
      parseFloat(place.lat),
      parseFloat(place.lon),
      osmId
    )
    // Don't redirect - let the UI show the pending state
  } catch (error) {
    console.error('Failed to submit place:', error)
    gameStore.clearSubmittedPlace()
  }
}

function handleSearchResults(places: NominatimPlace[]) {
  gameStore.setSearchResultPlaces(places)

  // Fit bounds to show all search results
  if (places.length > 0 && camera?.isLoaded.value) {
    const lngs = places.map((p) => parseFloat(p.lon))
    const lats = places.map((p) => parseFloat(p.lat))
    const bounds: [[number, number], [number, number]] = [
      [Math.min(...lngs), Math.min(...lats)],
      [Math.max(...lngs), Math.max(...lats)],
    ]
    camera.fitBounds(bounds, { padding: 100, duration: 1000, maxZoom: 10 })
  }
}

function handleSearchCancel() {
  gameStore.clearSearchResultPlaces()
  hoveredPlaceId.value = null
  router.push('/')
}

function handlePlaceHover(place: NominatimPlace | null) {
  if (place) {
    // Use nominatim-{place_id} to match the ID format in searchResultPlaces
    hoveredPlaceId.value = `nominatim-${place.place_id}`
  } else {
    hoveredPlaceId.value = null
  }
}
</script>

<template>
  <!-- UI overlay -->
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
          <GamePlaceSearch
            @select="handlePlaceSubmit"
            @cancel="handleSearchCancel"
            @search-results="handleSearchResults"
            @hover="handlePlaceHover"
          />
        </div>

        <!-- Game ended with submission (pending review) -->
        <div v-else-if="gameStore.isSubmissionPending" class="text-center space-y-4">
          <p class="text-2xl">Thank you!</p>
          <p class="text-muted-foreground">
            Your submission is pending review. Once approved, this place will help me learn!
          </p>
          <Button class="w-full" @click="router.push('/')">New Game</Button>
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
