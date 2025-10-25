<script setup lang="ts">
import { computed, onMounted, watchEffect, onUnmounted } from 'vue'
import HeroCard from '@/components/HeroCard.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapBounds } from '@/composables/map/useMapBounds'
import { useMapState } from '@/composables/map/useMapState'

const placesStore = usePlaces()
const { setMapState, clearMapState } = useMapState()

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Create GeoJSON for places clustering
const placesGeoJSON = computed(() => {
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

// Calculate bounds for all places
const markers = computed(() => {
  return placesStore.places
    .filter(p => p.lat !== null && p.lng !== null)
    .map(place => ({
      coordinates: [place.lng!, place.lat!] as [number, number]
    }))
})

const bounds = useMapBounds(markers)

// Update map state for browse mode (clustering, no individual markers)
watchEffect(() => {
  setMapState(
    bounds.value,
    [], // No individual markers in browse mode (use clustering)
    placesGeoJSON.value,
    true // isBrowseMode = true
  )
})

// Clear map state when component unmounts
onUnmounted(() => {
  clearMapState()
})
</script>

<template>
  <!-- Hero Card centered -->
  <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <HeroCard />
    </div>
  </div>
</template>
