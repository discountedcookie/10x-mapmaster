<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import MapView from '@/components/map/MapView.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useGameStore } from '@/stores/game'

const route = useRoute()
const { places: allPlaces, fetchAllPlaces } = usePlaces()
const gameStore = useGameStore()

onMounted(() => {
  fetchAllPlaces()
})

// Dynamically compute map candidates based on current route and game state
const mapCandidates = computed(() => {
  // In game view, show game candidates when there are candidates from the game
  if (route.name === 'game' && gameStore.topCandidates.length > 0) {
    return gameStore.topCandidates.map(place => ({
      lat: place.lat,
      lng: place.lng,
      name: place.name,
      similarity: place.composite_confidence,
    }))
  }

  // Otherwise show all places (home view or game not started)
  return allPlaces.value
})
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <!-- Floating Navigation Bar -->
    <FloatingNavbar />

    <!-- Map Background (persistent across routes) -->
    <MapView :candidates="mapCandidates" />

    <!-- Content Overlay (from slot) -->
    <slot />
  </div>
</template>
