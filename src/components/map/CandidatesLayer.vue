<script setup lang="ts">
import { ref, computed, watch, onUnmounted } from 'vue'
import { useMap, MglGeoJsonSource, MglCircleLayer, MglMarker } from '@indoorequal/vue-maplibre-gl'
import { isVisibleOnGlobe } from '@/composables/map/useGlobeVisibility'
import { useMapCenterTracking } from '@/composables/map/useMapCenterTracking'
import CandidateMarker from './CandidateMarker.vue'
import type { PlaceWithScore } from '@/types/game'
import type { CircleLayerSpecification } from 'maplibre-gl'

interface Properties {
  candidates: PlaceWithScore[]
  mapKey: symbol
  hideCircles?: boolean // Hide circles when 3D polygon is shown
  highlightedId?: string | undefined // ID of place to highlight on hover
}

const properties = defineProps<Properties>()

const mapInstance = useMap(properties.mapKey)

// Track map center for visibility filtering on globe
const { mapCenter } = useMapCenterTracking(mapInstance)

// Track zoom level for label visibility
const currentZoom = ref(5)
function updateZoom() {
  if (mapInstance.map) {
    currentZoom.value = mapInstance.map.getZoom()
  }
}

// Filter candidates to only those visible on the globe
const visibleCandidates = computed(() => {
  const center = mapCenter.value
  return properties.candidates.filter((c) => isVisibleOnGlobe(c.lng, c.lat, center.lng, center.lat))
})

// Convert candidates to GeoJSON for MapLibre
const candidatesGeoJson = computed(() => {
  const candidates = visibleCandidates.value

  return {
    type: 'FeatureCollection' as const,
    features: candidates.map((candidate, index) => {
      const rank = index + 1

      // Size based on rank
      let radius: number
      if (rank === 1) radius = 12
      else if (rank <= 3) radius = 10
      else radius = 8

      // Check if this candidate is highlighted
      const isHighlighted = properties.highlightedId === candidate.id

      return {
        type: 'Feature' as const,
        properties: {
          id: candidate.id,
          name: candidate.name,
          probability: candidate.probability,
          rank,
          radius,
          // Saturation and opacity based on probability (already 0-1)
          saturation: candidate.probability * 100,
          opacity: 0.3 + candidate.probability * 0.7, // Min 30% opacity so markers are always visible
          // Sort key for z-index: higher probability = higher z-index, highlighted gets priority
          sortKey: isHighlighted ? 10_000 : Math.round(candidate.probability * 1000),
          // Highlight state for styling
          highlighted: isHighlighted ? 1 : 0,
        },
        geometry: {
          type: 'Point' as const,
          coordinates: [candidate.lng, candidate.lat],
        },
      }
    }),
  }
})

// Simple, clean marker style - shadcn inspired
const markerPaint = computed((): CircleLayerSpecification['paint'] => ({
  'circle-radius': ['get', 'radius'],
  // Use primary blue (hsl 220) with saturation based on probability
  'circle-color': [
    'interpolate',
    ['linear'],
    ['get', 'saturation'],
    0,
    'hsl(220, 0%, 70%)', // Grey at 0% probability
    50,
    'hsl(220, 50%, 60%)', // Muted blue
    100,
    'hsl(220, 80%, 55%)', // Full primary blue
  ],
  'circle-stroke-color': 'hsl(0, 0%, 100%)',
  'circle-stroke-width': 2,
  'circle-opacity': ['get', 'opacity'],
  'circle-stroke-opacity': ['get', 'opacity'],
}))

// Layout properties for circle layer (includes sort-key for z-ordering)
const markerLayout = computed((): CircleLayerSpecification['layout'] => ({
  // Sort by probability so higher probability markers render on top
  'circle-sort-key': ['get', 'sortKey'],
}))

// Sort candidates by probability (ascending) so higher probability renders LAST (on top in DOM)
const sortedCandidatesForLabels = computed(() => {
  return visibleCandidates.value.toSorted((a, b) => a.probability - b.probability)
})

// Setup zoom tracking when map loads
watch(
  () => mapInstance.isLoaded,
  (isLoaded) => {
    if (isLoaded && mapInstance.map) {
      mapInstance.map.on('zoom', updateZoom)
      updateZoom()
    }
  },
  { immediate: true }
)

onUnmounted(() => {
  if (mapInstance.map) {
    mapInstance.map.off('zoom', updateZoom)
  }
})
</script>

<template>
  <MglGeoJsonSource source-id="candidate-points" :data="candidatesGeoJson">
    <!-- Simple circle marker - clean shadcn style (hidden when 3D polygon shown) -->
    <MglCircleLayer
      v-if="!hideCircles"
      layer-id="candidate-markers-layer"
      :paint="markerPaint"
      :layout="markerLayout"
    />
  </MglGeoJsonSource>

  <!-- HTML markers with Badge labels (sorted by probability, low→high so high renders on top) -->
  <template v-if="currentZoom >= 2">
    <MglMarker
      v-for="candidate in sortedCandidatesForLabels"
      :key="candidate.id"
      :coordinates="[candidate.lng, candidate.lat]"
      anchor="top"
      :offset="[0, 14]"
    >
      <template #marker>
        <CandidateMarker
          :name="candidate.name"
          :probability="candidate.probability"
          :zoom="currentZoom"
          :highlighted="highlightedId === candidate.id"
        />
      </template>
    </MglMarker>
  </template>
</template>
