<script setup lang="ts">
import { computed, onMounted, watchEffect, onUnmounted } from 'vue'
import HeroCard from '@/components/HeroCard.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapMarkers } from '@/composables/map/useMapMarkers'
import { useMapState } from '@/composables/map/useMapState'

const placesStore = usePlaces()
const { setMapState, clearMapState } = useMapState()

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Compute markers for browse mode
const { markerNodes, bounds } = useMapMarkers({
  data: computed(() => placesStore.places),
  markerComponent: MapMarker,
  computeMarker: (place) => ({
    id: `place-${place.id}`,
    coordinates: [place.lng!, place.lat!] as [number, number],
    name: place.name,
    backgroundColor: '#3b82f6',
    opacity: 1,
    similarity: undefined,
    gameCount: place.game_count,
  })
})

// Update map state when markers change
watchEffect(() => {
  setMapState(bounds.value, markerNodes.value)
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
