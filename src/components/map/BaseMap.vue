<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { MglMap } from '@indoorequal/vue-maplibre-gl'

interface Properties {
  bounds?: [[number, number], [number, number]]
  center?: [number, number]
  zoom?: number
}

const properties = withDefaults(defineProps<Properties>(), {
  center: () => [0, 20],
  zoom: 3,
})

const { resolvedTheme } = useTheme()
const mapRef = ref()

// Map configuration - theme-aware styles using free OSM tiles
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json'
    : 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json'
})

// Watch bounds changes and update map programmatically
// This ensures bounds updates trigger map repositioning, not just initial mount
watch(
  () => properties.bounds,
  (newBounds) => {
    if (newBounds && mapRef.value?.map) {
      // Use fitBounds with padding for smooth transitions
      mapRef.value.map.fitBounds(newBounds, {
        padding: 50,
        duration: 1000,
        maxZoom: 15, // Prevent zooming in too close
      })
    }
  },
  { deep: true }
)
</script>

<template>
  <div class="absolute inset-0">
    <MglMap ref="mapRef" :map-style="mapStyle" :center="center" :zoom="zoom" :bounds="bounds">
      <slot />
    </MglMap>
  </div>
</template>
