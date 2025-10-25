<script setup lang="ts">
import { computed, onMounted } from 'vue'
import MapLayout from '@/layouts/MapLayout.vue'
import HeroCard from '@/components/HeroCard.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapMarkers } from '@/composables/map/useMapMarkers'

const placesStore = usePlaces()

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
</script>

<template>
  <MapLayout :bounds="bounds">
    <template #markers>
      <component :is="() => markerNodes" />
    </template>
    <template #overlay>
      <HeroCard />
    </template>
  </MapLayout>
</template>
