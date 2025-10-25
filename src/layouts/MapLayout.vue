<script setup lang="ts">
import { computed, onMounted, watchEffect } from 'vue'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapState } from '@/composables/map/useMapState'
import { useMapBounds } from '@/composables/map/useMapBounds'

const { mapState, setMapState } = useMapState()
const placesStore = usePlaces()

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
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

// Store places for rendering in MapLayout
const places = computed(() => {
  return placesStore.places.filter(p => p.lat !== null && p.lng !== null)
})

// Update map state with bounds and place data
watchEffect(() => {
  setMapState(bounds.value, places.value)
})
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />

    <BaseMap
      :bounds="mapState.bounds"
    >
      <MapMarker
        v-for="(place, index) in mapState.places"
        :key="`marker-${place.id}`"
        :coordinates="[place.lng!, place.lat!]"
        :name="place.name"
        :game-count="place.game_count"
        :index="index"
        :background-color="(place as any).backgroundColor"
        :opacity="(place as any).opacity"
        :similarity="(place as any).similarity"
      />
    </BaseMap>

    <slot />
  </div>
</template>
