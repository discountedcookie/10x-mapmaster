<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useGameStore } from '@/stores/game'

const route = useRoute()
const placesStore = usePlaces()
const gameStore = useGameStore()

// Check if we're in game mode with active candidates
const isGameMode = computed(() => {
  return route.name === 'game' && gameStore.topCandidates.length > 0
})

// Check if we're in home/browse mode
const isBrowseMode = computed(() => {
  return route.name === 'home' || (route.name === 'game' && gameStore.topCandidates.length === 0)
})

// Create GeoJSON for places clustering
const placesGeoJSON = computed(() => {
  if (!isBrowseMode.value) return null
  
  const features = placesStore.places
    .filter(p => p.lat !== null && p.lng !== null)
    .map(place => ({
      type: 'Feature',
      properties: {
        id: place.id,
        name: place.name,
        game_count: place.game_count || 0
      },
      geometry: {
        type: 'Point',
        coordinates: [place.lng!, place.lat!]
      }
    }))

  return {
    type: 'FeatureCollection',
    features
  }
})

// Compute markers based on current mode
const markers = computed(() => {
  if (isGameMode.value) {
    // Game mode: Show candidates with similarity scores
    return gameStore.topCandidates
      .filter(place => place.lat !== null && place.lng !== null)
      .map((place, index) => {
        const backgroundColor = '#ef4444' // red-500
        const opacity = 0.4 + (place.composite_confidence * 0.6)

        return {
          id: `game-${index}`,
          coordinates: [place.lng!, place.lat!] as [number, number],
          name: place.name,
          backgroundColor,
          opacity,
          similarity: place.composite_confidence,
          gameCount: undefined,
        }
      })
  }

  // Browse mode: No individual markers (use clustering instead)
  return []
})

// Calculate bounds for all markers with padding
const bounds = computed(() => {
  if (isGameMode.value && markers.value.length > 0) {
    // Game mode: Use game markers bounds
    const lngs = markers.value.map(m => m.coordinates[0])
    const lats = markers.value.map(m => m.coordinates[1])

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    // Add 25% padding to bounds to avoid markers on the edge and prevent overlap
    const lngPadding = (maxLng - minLng) * 0.25
    const latPadding = (maxLat - minLat) * 0.25

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ] as [[number, number], [number, number]]
  }

  if (isBrowseMode.value && placesStore.places.length > 0) {
    // Browse mode: Use all places bounds
    const validPlaces = placesStore.places.filter(p => p.lat !== null && p.lng !== null)
    if (validPlaces.length === 0) return

    const lngs = validPlaces.map(p => p.lng!)
    const lats = validPlaces.map(p => p.lat!)

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    // Add 15% padding for browse mode
    const lngPadding = (maxLng - minLng) * 0.15
    const latPadding = (maxLat - minLat) * 0.15

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ] as [[number, number], [number, number]]
  }

  return undefined
})
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <!-- Floating Navigation Bar -->
    <FloatingNavbar />

    <!-- Single persistent map instance with dynamic markers -->
    <BaseMap 
      :bounds="bounds"
      :places-geo-json="placesGeoJSON"
      :is-browse-mode="isBrowseMode"
    >
      <MapMarker
        v-for="(marker, index) in markers"
        :key="marker.id"
        :coordinates="marker.coordinates"
        :name="marker.name"
        :background-color="marker.backgroundColor"
        :opacity="marker.opacity"
        :similarity="marker.similarity"
        :game-count="marker.gameCount"
        :index="index"
      />
    </BaseMap>

    <!-- Content overlays from slot (game cards, hero card, etc.) -->
    <slot />
  </div>
</template>
