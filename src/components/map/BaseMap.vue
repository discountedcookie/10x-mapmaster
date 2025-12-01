<script lang="ts">
// Named export for backward compatibility
export { MAP_KEY as BASE_MAP_KEY } from '@/composables/map/useMapCamera'
</script>

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { MglMap, useMap } from '@indoorequal/vue-maplibre-gl'
import { MAP_KEY } from '@/composables/map/useMapCamera'
import { useMapLayersStore } from '@/stores/mapLayers'
import type { ProjectionSpecification, SkySpecification } from 'maplibre-gl'

/**
 * BaseMap - Dumb container for the map.
 *
 * Responsibilities:
 * - Render MglMap with globe projection
 * - Apply theme-aware styling
 * - Provide slot for layer components
 *
 * Does NOT handle:
 * - Camera control (use useMapCamera)
 * - Auto-rotation (use useAutoRotation)
 * - Route handling (views handle this)
 * - Layer management (views render their own layers)
 */

const { resolvedTheme } = useTheme()
const mapInstance = useMap(MAP_KEY)
const mapLayersStore = useMapLayersStore()

// Globe-compatible basemap - CartoDB no-labels (cleaner for polygon overlays)
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? 'https://basemaps.cartocdn.com/gl/dark-matter-nolabels-gl-style/style.json'
    : 'https://basemaps.cartocdn.com/gl/positron-nolabels-gl-style/style.json'
})

// Theme-aware atmospheric colors for globe
// Creates a subtle vignette effect - lighter near globe, darker at edges
const skyOptions = computed((): SkySpecification => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? {
        'sky-color': '#0a0a0a', // outer edge - darkest
        'horizon-color': '#151515', // middle transition
        'fog-color': '#1a1a1a', // near globe - slightly lighter
        'sky-horizon-blend': 0.5,
        'horizon-fog-blend': 0.7,
        'fog-ground-blend': 0.8,
        'atmosphere-blend': 0.85,
      }
    : {
        'sky-color': '#d8d8d8', // outer edge - slightly gray
        'horizon-color': '#e8e8e8', // middle transition
        'fog-color': '#f5f5f5', // near globe - almost white
        'sky-horizon-blend': 0.5,
        'horizon-fog-blend': 0.7,
        'fog-ground-blend': 0.8,
        'atmosphere-blend': 0.85,
      }
})

// Globe projection configuration
const globeProjection: ProjectionSpecification = { type: 'globe' }

// Apply globe projection and atmospheric effects
function setupGlobe() {
  const map = mapInstance.map
  if (!map) return

  // Enable globe projection
  map.setProjection(globeProjection)

  // Apply atmospheric sky for realistic Earth appearance
  map.setSky(skyOptions.value)

  // Enable pitch/rotation controls
  map.dragRotate.enable()
  map.touchPitch.enable()
  map.keyboard.enable()
}

// Handle map load event
let hasSetInitialPosition = false
function onMapLoaded() {
  setupGlobe()

  // Set initial position only on first load, if camera hasn't been moved yet
  const map = mapInstance.map
  if (map && !hasSetInitialPosition) {
    hasSetInitialPosition = true
    // Only set default position if camera is still at initial state
    const center = map.getCenter()
    const zoom = map.getZoom()
    // If camera hasn't been moved from default, set it
    if (Math.abs(center.lng) < 1 && Math.abs(center.lat - 20) < 1 && zoom < 3) {
      map.jumpTo({
        center: [0, 20],
        zoom: 2,
        pitch: 0,
      })
    }
  }
}

// Re-apply globe settings when theme changes
watch(resolvedTheme, () => {
  const map = mapInstance.map
  if (map) {
    map.once('style.load', () => {
      setupGlobe()
    })
  }
})
</script>

<template>
  <div class="absolute inset-0">
    <MglMap
      :map-key="MAP_KEY"
      :map-style="mapStyle"
      :min-zoom="1"
      :max-zoom="18"
      :max-pitch="85"
      :drag-rotate="true"
      :touch-pitch="true"
      :canvas-context-attributes="{ antialias: true }"
      @map:load="onMapLoaded"
    >
      <!-- Render map layers from store -->
      <component
        :is="layer.component"
        v-for="layer in mapLayersStore.layers"
        :key="layer.key"
        v-bind="layer.props || {}"
      />
    </MglMap>
  </div>
</template>
