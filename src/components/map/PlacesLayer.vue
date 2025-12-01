<script setup lang="ts">
import { watch, computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  useMap,
  MglGeoJsonSource,
  MglFillLayer,
  MglCircleLayer,
  MglMarker,
} from '@indoorequal/vue-maplibre-gl'
import { isVisibleOnGlobe } from '@/composables/map/useGlobeVisibility'
import { useMapCenterTracking } from '@/composables/map/useMapCenterTracking'
import PlaceMarker from './PlaceMarker.vue'
import type { Place } from '@/stores/places'
import type { FillLayerSpecification, CircleLayerSpecification } from 'maplibre-gl'

interface Properties {
  places: Place[]
  mapKey: symbol
}

const properties = defineProps<Properties>()

const router = useRouter()
const mapInstance = useMap(properties.mapKey)

// Track map center for visibility filtering
const { mapCenter } = useMapCenterTracking(mapInstance)

// Track zoom level for label visibility
const currentZoom = ref(2)
function updateZoom() {
  if (mapInstance.map) {
    currentZoom.value = mapInstance.map.getZoom()
  }
}

// Filter places to only those visible on the globe
const visiblePlaces = computed(() => {
  const center = mapCenter.value
  return properties.places.filter(
    (p) =>
      p.lat != undefined &&
      p.lng != undefined &&
      isVisibleOnGlobe(p.lng, p.lat, center.lng, center.lat)
  )
})

// GeoJSON for polygon geometries (places that have real geometry)
const polygonsGeoJson = computed(() => ({
  type: 'FeatureCollection' as const,
  features: visiblePlaces.value
    .filter((p) => p.geometry && typeof p.geometry === 'object' && 'type' in p.geometry)
    .map((place) => ({
      type: 'Feature' as const,
      properties: {
        id: place.id,
        name: place.name,
      },
      geometry: place.geometry as unknown as GeoJSON.Polygon | GeoJSON.MultiPolygon,
    })),
}))

// GeoJSON for point markers (all places - shown at low zoom)
const pointsGeoJson = computed(() => ({
  type: 'FeatureCollection' as const,
  features: visiblePlaces.value
    .filter((p) => p.lat != undefined && p.lng != undefined)
    .map((place) => ({
      type: 'Feature' as const,
      properties: {
        id: place.id,
        name: place.name,
        hasGeometry: !!(place.geometry && typeof place.geometry === 'object'),
      },
      geometry: {
        type: 'Point' as const,
        coordinates: [place.lng!, place.lat!] as [number, number],
      },
    })),
}))

// Circle markers - visible at low zoom, fade out when polygons become visible
const circlePaint = computed((): CircleLayerSpecification['paint'] => ({
  'circle-radius': ['interpolate', ['linear'], ['zoom'], 0, 4, 4, 6, 8, 10, 12, 14],
  'circle-color': '#3b82f6',
  'circle-stroke-color': '#ffffff',
  'circle-stroke-width': 2,
  // Hide circles for places with geometry at high zoom
  'circle-opacity': [
    'interpolate',
    ['linear'],
    ['zoom'],
    0,
    1,
    10,
    1,
    12,
    ['case', ['get', 'hasGeometry'], 0, 1],
  ],
  'circle-stroke-opacity': [
    'interpolate',
    ['linear'],
    ['zoom'],
    0,
    1,
    10,
    1,
    12,
    ['case', ['get', 'hasGeometry'], 0, 1],
  ],
}))

// Polygon fill - only visible at higher zoom
const fillPaint = computed((): FillLayerSpecification['paint'] => ({
  'fill-color': '#3b82f6',
  'fill-opacity': ['interpolate', ['linear'], ['zoom'], 10, 0, 12, 0.6],
}))

// Navigate to place when marker is clicked
function handleMarkerClick(placeId: string) {
  router.push(`/places/${placeId}`)
}

function setupEventListeners() {
  const map = mapInstance.map
  if (!map) return

  // Track zoom changes for label visibility
  map.on('zoom', updateZoom)
  updateZoom()

  // Click handlers - navigate to place route
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleClick = (e: any) => {
    if (!e.features?.length) return
    const feature = e.features[0]
    const placeId = feature.properties?.id

    if (placeId) {
      router.push(`/places/${placeId}`)
    }
  }

  map.on('click', 'places-circles-layer', handleClick)
  map.on('click', 'places-fill-layer', handleClick)

  // Cursor change on hover
  const handleMouseEnter = () => {
    map.getCanvas().style.cursor = 'pointer'
  }

  const handleMouseLeave = () => {
    map.getCanvas().style.cursor = ''
  }

  map.on('mouseenter', 'places-circles-layer', handleMouseEnter)
  map.on('mouseleave', 'places-circles-layer', handleMouseLeave)
  map.on('mouseenter', 'places-fill-layer', handleMouseEnter)
  map.on('mouseleave', 'places-fill-layer', handleMouseLeave)
}

watch(
  () => mapInstance.isLoaded,
  (isLoaded) => {
    if (isLoaded) {
      setupEventListeners()
    }
  },
  { immediate: true }
)
</script>

<template>
  <!-- Circle markers for all places (visible at low zoom) -->
  <MglGeoJsonSource source-id="places-points" :data="pointsGeoJson">
    <MglCircleLayer layer-id="places-circles-layer" :paint="circlePaint" />
  </MglGeoJsonSource>

  <!-- Polygon fills (visible at high zoom) -->
  <MglGeoJsonSource source-id="places-polygons" :data="polygonsGeoJson">
    <MglFillLayer layer-id="places-fill-layer" :paint="fillPaint" />
  </MglGeoJsonSource>

  <!-- HTML markers with Badge labels (render from zoom 3 so fade-out works, visible from 4+) -->
  <template v-if="currentZoom >= 3">
    <MglMarker
      v-for="place in visiblePlaces.filter((p) => p.id && p.name)"
      :key="place.id!"
      :coordinates="[place.lng!, place.lat!]"
      anchor="top"
      :offset="[0, 10]"
    >
      <template #marker>
        <PlaceMarker
          :name="place.name!"
          :zoom="currentZoom"
          @click="handleMarkerClick(place.id!)"
        />
      </template>
    </MglMarker>
  </template>
</template>
