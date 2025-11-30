<script setup lang="ts">
import { ref, watch, computed, onMounted, onUnmounted, watchEffect } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMediaQuery, breakpointsTailwind } from '@vueuse/core'
import { useMapCamera, MAP_KEY } from '@/composables/map/useMapCamera'
import { usePlaces } from '@/composables/usePlaces'
import { useMapLayersStore } from '@/stores/mapLayers'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { supabase } from '@/lib/supabase'
import { X } from 'lucide-vue-next'
import PlacesLayer from '@/components/map/PlacesLayer.vue'
import type { Tables } from '@/types/database'

const route = useRoute()
const router = useRouter()
const placesStore = usePlaces()
const camera = useMapCamera()
const mapLayersStore = useMapLayersStore()

// Responsive breakpoints
// md (768px+): tablet/medium - card takes left half
// xl (1280px+): large desktop - card takes left third
const isDesktop = useMediaQuery('(min-width: 768px)')
const isLargeDesktop = useMediaQuery(`(min-width: ${breakpointsTailwind.xl}px)`)

// GeoJSON geometry type (for bbox computation)
type GeoJSONGeometry = {
  type: string
  coordinates: number[] | number[][] | number[][][] | number[][][][]
}

// Place type from database view
type PlaceWithGeometry = Tables<'places_with_geometry'>

// State
const loading = ref(true)
const place = ref<PlaceWithGeometry | null>(null)
const traits = ref<string[]>([])

// Get place ID from route
const placeId = computed(() => route.params.id as string)

// Fetch place details and traits
async function fetchPlaceDetails() {
  if (!placeId.value) return

  loading.value = true

  try {
    // Get place from store or fetch
    const storePlace = (placesStore.places as any[]).find((p: any) => p.id === placeId.value)

    if (storePlace) {
      place.value = storePlace as PlaceWithGeometry
    } else {
      // Fetch from database
      const { data, error } = await supabase
        .from('places_with_geometry')
        .select('*')
        .eq('id', placeId.value)
        .single()

      if (error || !data) {
        // Place not found - redirect to home
        router.replace('/')
        return
      }

      place.value = data
    }

    // Fetch traits
    const { data: traitsData } = await supabase
      .from('place_traits')
      .select('trait_id, traits(clause)')
      .eq('place_id', placeId.value)

    if (traitsData) {
      traits.value = traitsData
        .map((row: any) => row.traits?.clause)
        .filter((clause: string | undefined): clause is string => !!clause)
    }
  } catch (error) {
    console.error('Failed to fetch place details:', error)
  } finally {
    loading.value = false
  }
}

/**
 * Compute bounding box from GeoJSON geometry
 * Returns [minLng, minLat, maxLng, maxLat] or null if no geometry
 */
function computeBbox(geometry: unknown): [number, number, number, number] | null {
  if (!geometry || typeof geometry !== 'object') return null
  const geom = geometry as GeoJSONGeometry
  if (!geom.coordinates) return null

  let minLng = Infinity
  let minLat = Infinity
  let maxLng = -Infinity
  let maxLat = -Infinity

  function processCoord(coord: number[]) {
    const [lng, lat] = coord
    if (lng !== undefined && lat !== undefined) {
      minLng = Math.min(minLng, lng)
      minLat = Math.min(minLat, lat)
      maxLng = Math.max(maxLng, lng)
      maxLat = Math.max(maxLat, lat)
    }
  }

  function processCoords(coords: any) {
    if (typeof coords[0] === 'number') {
      // It's a single coordinate [lng, lat]
      processCoord(coords as number[])
    } else {
      // It's an array of coordinates or nested arrays
      for (const c of coords) {
        processCoords(c)
      }
    }
  }

  processCoords((geometry as any).coordinates)

  if (minLng === Infinity) return null
  return [minLng, minLat, maxLng, maxLat]
}

/**
 * Calculate offset so place appears in visible area (not behind card)
 * Desktop: Card takes left half, place should be centered in the right half
 * Mobile: Card takes bottom 1/3, place should be centered in top 2/3
 *
 * Returns pixel offset [x, y] to apply to the map center
 */
function getMapOffset(): { x: number; y: number } {
  if (!camera) return { x: 0, y: 0 }
  const map = camera.map.value
  if (!map) return { x: 0, y: 0 }

  const container = map.getContainer()
  const width = container.clientWidth
  const height = container.clientHeight

  if (isLargeDesktop.value) {
    // Large desktop (xl+): Card panel occupies left 1/3 of viewport
    // To center the place in the right 2/3, offset by 1/6 of viewport width
    return { x: width / 6, y: 0 }
  } else if (isDesktop.value) {
    // Medium desktop (md-xl): Card panel occupies left 1/2 of viewport
    // To center the place in the right 1/2, offset by 1/4 of viewport width
    return { x: width / 4, y: 0 }
  } else {
    // Mobile: Card takes bottom 1/3
    // Offset the map center upward so place appears in top 2/3
    const cardHeight = height / 3
    return { x: 0, y: -cardHeight / 2 }
  }
}

/**
 * Calculate appropriate zoom level for a bounding box
 * Uses logarithmic scale: zoom ≈ -log2(degrees) + offset
 */
function getZoomForBbox(bbox: [number, number, number, number]): number {
  const [minLng, minLat, maxLng, maxLat] = bbox
  const lngDiff = maxLng - minLng
  const latDiff = maxLat - minLat
  const maxDiff = Math.max(lngDiff, latDiff, 0.0001) // Prevent log(0)

  // Logarithmic relationship: each zoom level halves the visible area
  // zoom = -log2(degrees) + constant, clamped to reasonable range
  const zoom = -Math.log2(maxDiff) + 8
  return Math.min(Math.max(zoom, 5), 17)
}

// Fly to place with offset when loaded (using bbox to calculate zoom)
// Also sets up 3D view with pitch
async function flyToPlace() {
  if (!camera || !place.value || !camera.isLoaded.value) return
  if (place.value.lat == null || place.value.lng == null) return

  const bbox = computeBbox((place.value as any).geometry)
  const offset = getMapOffset()

  // Calculate zoom from bbox if available, otherwise use default
  const zoom = bbox ? getZoomForBbox(bbox) : 12

  // Fly to place with 3D pitch and offset to position it correctly
  await camera.flyTo({
    center: [place.value.lng, place.value.lat],
    zoom,
    pitch: 55,
    bearing: 0,
    duration: 1500,
    offset: [offset.x, offset.y],
  })

  // Start rotation animation after fly completes
  startRotation()
}

// Handle map movement - reset URL if place goes out of bounds
function handleCameraChange() {
  if (!camera || !place.value) return
  if (place.value.lat == null || place.value.lng == null) return

  // Check if place is still visible
  if (!camera.isInBounds(place.value.lng, place.value.lat)) {
    router.replace('/')
  }
}

// ===== 3D Extrusion Layer Setup =====
// Adds extruded building polygon or circle marker to the map
function setup3DLayer() {
  if (!camera || !place.value || !camera.map.value) return
  const map = camera.map.value
  const placeData = place.value as any
  if (!placeData.geometry) return

  const sourceId = 'place-extrusion-source'
  const layerId = 'place-extrusion-layer'

  // Remove existing layer and source if present
  if (map.getLayer(layerId)) {
    map.removeLayer(layerId)
  }
  if (map.getSource(sourceId)) {
    map.removeSource(sourceId)
  }

  const geomType = placeData.geometry?.type

  // Create GeoJSON source from place geometry
  map.addSource(sourceId, {
    type: 'geojson',
    data: {
      type: 'Feature',
      properties: {},
      geometry:
        geomType === 'Point'
          ? { type: 'Point', coordinates: [placeData.lng, placeData.lat] }
          : (placeData.geometry as any),
    },
  })

  if (geomType === 'Point') {
    // Circle marker for point geometries (mountains, peaks, etc.)
    map.addLayer({
      id: layerId,
      type: 'circle',
      source: sourceId,
      paint: {
        'circle-radius': ['interpolate', ['linear'], ['zoom'], 8, 10, 12, 14, 16, 20],
        'circle-color': '#3b82f6',
        'circle-stroke-color': '#ffffff',
        'circle-stroke-width': 2,
      },
    })
  } else {
    // Determine if this is a large area (city) or small area (building)
    // Use bbox computed from geometry to check geographic span
    const bbox = computeBbox(placeData.geometry)
    const isLargeArea = bbox
      ? Math.max(bbox[2] - bbox[0], bbox[3] - bbox[1]) > 0.05 // > ~5km span
      : false

    if (isLargeArea) {
      // Flat fill for large areas (city boundaries)
      // More reliable rendering and looks better at low zoom
      map.addLayer({
        id: layerId,
        type: 'fill',
        source: sourceId,
        paint: {
          'fill-color': '#fb923c',
          'fill-opacity': 0.5,
          'fill-outline-color': '#ea580c',
        },
      })
    } else {
      // Fill-extrusion for small areas (buildings)
      map.addLayer({
        id: layerId,
        type: 'fill-extrusion',
        source: sourceId,
        paint: {
          'fill-extrusion-color': '#fb923c',
          'fill-extrusion-opacity': 0.7,
          'fill-extrusion-height': [
            'interpolate',
            ['linear'],
            ['zoom'],
            12,
            0,
            14,
            30,
            16,
            60,
            18,
            100,
          ],
          'fill-extrusion-base': 0,
        },
        minzoom: 12,
      })
    }
  }
}

function cleanup3DLayer() {
  if (!camera || !camera.map.value) return
  const map = camera.map.value

  const sourceId = 'place-extrusion-source'
  const layerId = 'place-extrusion-layer'

  if (map.getLayer(layerId)) {
    map.removeLayer(layerId)
  }
  if (map.getSource(sourceId)) {
    map.removeSource(sourceId)
  }
}

// ===== Rotation Animation =====
// Continuous 360-degree rotation around the place center
const rotationConfig = {
  // Duration for one full 360-degree rotation in milliseconds
  rotationDuration: 30000, // 30 seconds per rotation
  // Whether rotation is currently active
  isRotating: ref(false),
}

let rotationAnimationId: number | null = null
let rotationStartTime: number | null = null

function startRotation() {
  if (!camera || !place.value || !camera.map.value) return
  if (place.value.lng == null || place.value.lat == null) return
  if (rotationConfig.isRotating.value) return

  rotationConfig.isRotating.value = true
  rotationStartTime = performance.now()

  const map = camera.map.value
  const offset = getMapOffset()

  // The rotation center is the place's actual coordinates
  const rotationCenter = {
    lng: place.value.lng,
    lat: place.value.lat,
  }

  function animate(currentTime: number) {
    if (!rotationConfig.isRotating.value || !camera || !camera.map.value) return
    if (!place.value || place.value.lat == null || place.value.lng == null) return

    const map = camera.map.value
    const elapsed = currentTime - (rotationStartTime || currentTime)

    // Calculate bearing: 0 to 360 degrees based on elapsed time
    const bearing = (elapsed / rotationConfig.rotationDuration) * 360

    // Rotate the bearing and also apply the offset with flyTo
    // This keeps the place visually in the same position while the globe spins
    map.setBearing(bearing % 360)
    map.flyTo({
      center: [rotationCenter.lng, rotationCenter.lat],
      offset: [offset.x, offset.y],
      duration: 0, // instant, no animation
      zoom: map.getZoom(),
    })

    // Continue animation
    rotationAnimationId = requestAnimationFrame(animate)
  }

  rotationAnimationId = requestAnimationFrame(animate)
}

function stopRotation() {
  rotationConfig.isRotating.value = false
  if (rotationAnimationId !== null) {
    cancelAnimationFrame(rotationAnimationId)
    rotationAnimationId = null
  }
  rotationStartTime = null
}

// Watch for place ID changes
watch(
  placeId,
  () => {
    // Stop rotation when changing places
    stopRotation()
    cleanup3DLayer()
    fetchPlaceDetails()
  },
  { immediate: true }
)

// Fly when place is loaded AND map is ready
let initialLoadComplete = false
watch(
  () => camera.isLoaded.value,
  (isLoaded) => {
    if (place.value && isLoaded) {
      flyToPlace()
    }
  },
  { immediate: true }
)

// Watch camera center for out-of-bounds detection (only after initial load)
watch(
  () => camera.center.value,
  () => {
    if (initialLoadComplete && !camera.isAnimating.value) {
      handleCameraChange()
    }
  }
)

// Mark initial load complete after first fly
watch(
  () => camera.isAnimating.value,
  (animating, wasAnimating) => {
    if (wasAnimating && !animating && place.value) {
      initialLoadComplete = true
    }
  }
)

// Setup 3D extrusion layer when place and map are ready
watchEffect(() => {
  if (place.value && camera.isLoaded.value && camera.map.value) {
    setup3DLayer()
  }
})

// Register map layers when place is loaded
watch(
  () => place.value,
  (newPlace: any) => {
    if (newPlace) {
      mapLayersStore.setLayers([
        {
          key: 'places',
          component: PlacesLayer,
          props: {
            places: placesStore.places,
            mapKey: MAP_KEY,
          },
        },
      ])
    }
  }
)

// Cleanup on unmount
onUnmounted(() => {
  stopRotation()
  cleanup3DLayer()
})

// Close panel and go back
function close() {
  router.push('/')
}
</script>

<template>
  <!-- Root wrapper to handle class attributes from RouterView -->
  <div>
    <!-- Desktop: Left panel, centered both vertically and horizontally -->
    <!-- md-xl: left half, xl+: left third -->
    <div
      class="fixed left-0 top-0 bottom-0 w-1/2 xl:w-1/3 z-20 pointer-events-none md:flex hidden items-center justify-center p-4"
    >
      <Card
        class="pointer-events-auto shadow-xl overflow-hidden flex flex-col w-80"
        style="max-height: 50vh"
      >
        <CardHeader class="flex-row items-start justify-between space-y-0 pb-3">
          <div class="space-y-1 flex-1 min-w-0">
            <Skeleton v-if="loading" class="h-6 w-3/4" />
            <CardTitle v-else class="text-lg truncate">{{ place?.name }}</CardTitle>

            <Skeleton v-if="loading" class="h-4 w-1/2" />
            <p v-else-if="place?.times_encountered" class="text-xs text-muted-foreground">
              Played {{ place.times_encountered }}
              {{ place.times_encountered === 1 ? 'time' : 'times' }}
            </p>
          </div>
          <Button variant="ghost" size="icon" class="shrink-0 -mr-2 -mt-2" @click="close">
            <X class="h-4 w-4" />
          </Button>
        </CardHeader>

        <CardContent class="flex-1 overflow-y-auto space-y-4">
          <div v-if="loading" class="space-y-2">
            <Skeleton class="h-4 w-full" />
            <Skeleton class="h-4 w-5/6" />
            <Skeleton class="h-4 w-4/6" />
          </div>

          <div v-else-if="traits.length > 0" class="space-y-3">
            <p class="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              What I know about this place
            </p>
            <ul class="space-y-2">
              <li v-for="trait in traits" :key="trait" class="text-sm flex items-start gap-2">
                <span class="text-primary mt-0.5">•</span>
                <span>{{ trait }}</span>
              </li>
            </ul>
          </div>

          <p v-else class="text-sm text-muted-foreground italic">
            I don't know anything about this place yet.
          </p>
        </CardContent>
      </Card>
    </div>

    <!-- Mobile: Bottom card, 1/3 height -->
    <div class="fixed left-4 right-4 bottom-4 z-20 pointer-events-none md:hidden">
      <Card
        class="pointer-events-auto shadow-xl overflow-hidden flex flex-col"
        style="max-height: 33vh"
      >
        <CardHeader class="flex-row items-start justify-between space-y-0 pb-3">
          <div class="space-y-1 flex-1 min-w-0">
            <Skeleton v-if="loading" class="h-6 w-3/4" />
            <CardTitle v-else class="text-lg truncate">{{ place?.name }}</CardTitle>

            <Skeleton v-if="loading" class="h-4 w-1/2" />
            <p v-else-if="place?.times_encountered" class="text-xs text-muted-foreground">
              Played {{ place.times_encountered }}
              {{ place.times_encountered === 1 ? 'time' : 'times' }}
            </p>
          </div>
          <Button variant="ghost" size="icon" class="shrink-0 -mr-2 -mt-2" @click="close">
            <X class="h-4 w-4" />
          </Button>
        </CardHeader>

        <CardContent class="flex-1 overflow-y-auto space-y-4">
          <div v-if="loading" class="space-y-2">
            <Skeleton class="h-4 w-full" />
            <Skeleton class="h-4 w-5/6" />
          </div>

          <div v-else-if="traits.length > 0" class="space-y-3">
            <p class="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              What I know about this place
            </p>
            <ul class="space-y-2">
              <li v-for="trait in traits" :key="trait" class="text-sm flex items-start gap-2">
                <span class="text-primary mt-0.5">•</span>
                <span>{{ trait }}</span>
              </li>
            </ul>
          </div>

          <p v-else class="text-sm text-muted-foreground italic">
            I don't know anything about this place yet.
          </p>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
