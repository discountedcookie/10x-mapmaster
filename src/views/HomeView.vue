<script setup lang="ts">
import { computed, onMounted } from 'vue'
import HeroCard from '@/components/HeroCard.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapBounds } from '@/composables/map/useMapBounds'
import { useMapState } from '@/composables/map/useMapState'

const { setMapState } = useMapState()
const placesStore = usePlaces()

// Calculate bounds for all places
const markers = computed(() => {
  return placesStore.places
    .filter(p => p.lat !== null && p.lng !== null)
    .map(place => ({
      coordinates: [place.lng!, place.lat!] as [number, number]
    }))
})

const bounds = useMapBounds(markers)

// Store places for map rendering
const places = computed(() => {
  return placesStore.places.filter(p => p.lat !== null && p.lng !== null)
})

// Restore all places when HomeView mounts
onMounted(() => {
  if (places.value.length > 0 && bounds.value) {
    setMapState(bounds.value, places.value)
  }
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
