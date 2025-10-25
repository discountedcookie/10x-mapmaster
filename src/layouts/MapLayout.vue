<script setup lang="ts">
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'
import { useMapState } from '@/composables/map/useMapState'

const { mapState } = useMapState()
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />

    <BaseMap
      :bounds="mapState.bounds"
      :places-geo-json="mapState.placesGeoJson"
      :is-browse-mode="mapState.isBrowseMode"
    >
      <component
        v-for="(node, index) in mapState.markerNodes"
        :key="`marker-${index}`"
        :is="node"
      />
    </BaseMap>

    <slot />
  </div>
</template>
