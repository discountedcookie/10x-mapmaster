<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapState } from '@/composables/map/useMapState'
import { useMapBounds } from '@/composables/map/useMapBounds'

const { mapState } = useMapState()
const placesStore = usePlaces()

// Fetch places on mount (will also set up realtime subscription)
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Clean up realtime subscription on unmount
onUnmounted(() => {
  placesStore.unsubscribeRealtime()
})

// Determine if we should show all places (no active game) or only candidates
const showAllPlaces = computed(() => mapState.value.candidates.length === 0)

// Calculate bounds based on active markers (candidates if game active, otherwise all places)
// This automatically recalculates whenever candidates or places change
const markers = computed(() => {
  // If we have candidates, use them for bounds
  if (mapState.value.candidates.length > 0) {
    return mapState.value.candidates.map((candidate) => ({
      coordinates: [candidate.lng, candidate.lat] as [number, number],
    }))
  }

  // Otherwise use all places
  return placesStore.places.map((place) => ({
    coordinates: [place.lng!, place.lat!] as [number, number],
  }))
})

// Bounds automatically update when markers change
const bounds = useMapBounds(markers)
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />

    <BaseMap :bounds="bounds" class="absolute inset-0">
      <!-- Database places (blue markers) - only show when no active game -->
      <MapMarker
        v-if="showAllPlaces"
        v-for="(place, index) in placesStore.places"
        :key="`place-${place.id}`"
        :coordinates="[place.lng, place.lat]"
        :name="place.name"
        :game-count="place.times_encountered"
        :index="index"
      />

      <!-- Candidate markers (from game) - only show during active game -->
      <MapMarker
        v-else
        v-for="(candidate, index) in mapState.candidates"
        :key="`candidate-${candidate.id}`"
        :coordinates="[candidate.lng, candidate.lat]"
        :name="candidate.name"
        :index="index"
        :similarity="candidate.confidence"
        :rank="index + 1"
      />
    </BaseMap>

    <!-- UI elements outside map -->
    <slot />
  </div>
</template>
