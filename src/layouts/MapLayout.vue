<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import MapView from '@/components/map/MapView.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useGameStore } from '@/stores/game'

const route = useRoute()
const placesStore = usePlaces()
const gameStore = useGameStore()

onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Dynamically compute map candidates based on current route and game state
const mapCandidates = computed(() => {
  // In game view, show game candidates when there are candidates from the game
  if (route.name === 'game' && gameStore.topCandidates.length > 0) {
    return gameStore.topCandidates
      .filter(place => place.lat !== null && place.lng !== null)
      .map(place => ({
        lat: place.lat!,
        lng: place.lng!,
        name: place.name,
        similarity: place.composite_confidence,
      }))
  }

  // Otherwise show all places (home view or game not started)
  return placesStore.places.filter(p => p.lat !== null && p.lng !== null)
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
