import { ref, computed, watch, shallowRef } from 'vue'
import { useMap } from '@indoorequal/vue-maplibre-gl'
import type { Map, FlyToOptions, EaseToOptions, FitBoundsOptions, LngLatBoundsLike } from 'maplibre-gl'

export const MAP_KEY = Symbol.for('baseMap')

interface MapCameraState {
  center: { lng: number; lat: number }
  zoom: number
  pitch: number
  bearing: number
}

interface UseMapCameraOptions {
  /** Initial center [lng, lat] */
  initialCenter?: [number, number]
  /** Initial zoom level */
  initialZoom?: number
  /** Sync state from map movements (default: true) */
  syncFromMap?: boolean
}

/**
 * Composable for controlling map camera with predictable state ownership.
 *
 * State is owned by the composable and synced TO the map.
 * When syncFromMap is true, user interactions update the state.
 * Views control the camera by updating state or calling methods.
 */
export function useMapCamera(options: UseMapCameraOptions = {}) {
  const {
    initialCenter = [0, 20],
    initialZoom = 2,
    syncFromMap = true,
  } = options

  const mapInstance = useMap(MAP_KEY)

  // Owned state - source of truth for camera position
  const center = ref<{ lng: number; lat: number }>({
    lng: initialCenter[0],
    lat: initialCenter[1],
  })
  const zoom = ref(initialZoom)
  const pitch = ref(0)
  const bearing = ref(0)

  // Animation state
  const isAnimating = ref(false)
  const isLoaded = computed(() => mapInstance.isLoaded)

  // Track if we're programmatically moving (to avoid feedback loops)
  let isProgrammaticMove = false

  // Get the raw map instance (for advanced usage)
  const map = computed(() => mapInstance.map)

  // Sync state from map on user interaction
  function syncStateFromMap() {
    if (!mapInstance.map || isProgrammaticMove) return

    const mapCenter = mapInstance.map.getCenter()
    center.value = { lng: mapCenter.lng, lat: mapCenter.lat }
    zoom.value = mapInstance.map.getZoom()
    pitch.value = mapInstance.map.getPitch()
    bearing.value = mapInstance.map.getBearing()
  }

  // Setup map event listeners when map is ready
  function setupMapListeners() {
    const m = mapInstance.map
    if (!m || !syncFromMap) return

    m.on('moveend', syncStateFromMap)
    m.on('zoomend', syncStateFromMap)
    m.on('pitchend', syncStateFromMap)
    m.on('rotateend', syncStateFromMap)
  }

  function cleanupMapListeners() {
    const m = mapInstance.map
    if (!m) return

    m.off('moveend', syncStateFromMap)
    m.off('zoomend', syncStateFromMap)
    m.off('pitchend', syncStateFromMap)
    m.off('rotateend', syncStateFromMap)
  }

  // Watch for map load and setup listeners
  watch(
    () => mapInstance.isLoaded,
    (loaded) => {
      if (loaded) {
        setupMapListeners()
        // Sync initial state from map
        syncStateFromMap()
      }
    },
    { immediate: true }
  )

  /**
   * Fly to a location with animation
   */
  function flyTo(options: FlyToOptions): Promise<void> {
    return new Promise((resolve) => {
      const m = mapInstance.map
      if (!m) {
        resolve()
        return
      }

      isProgrammaticMove = true
      isAnimating.value = true

      // Update owned state
      if (options.center) {
        const [lng, lat] = options.center as [number, number]
        center.value = { lng, lat }
      }
      if (options.zoom !== undefined) {
        zoom.value = options.zoom
      }
      if (options.pitch !== undefined) {
        pitch.value = options.pitch
      }
      if (options.bearing !== undefined) {
        bearing.value = options.bearing
      }

      m.once('moveend', () => {
        isProgrammaticMove = false
        isAnimating.value = false
        resolve()
      })

      m.flyTo(options)
    })
  }

  /**
   * Ease to a location with animation
   */
  function easeTo(options: EaseToOptions): Promise<void> {
    return new Promise((resolve) => {
      const m = mapInstance.map
      if (!m) {
        resolve()
        return
      }

      isProgrammaticMove = true
      isAnimating.value = true

      // Update owned state
      if (options.center) {
        const [lng, lat] = options.center as [number, number]
        center.value = { lng, lat }
      }
      if (options.zoom !== undefined) {
        zoom.value = options.zoom
      }
      if (options.pitch !== undefined) {
        pitch.value = options.pitch
      }
      if (options.bearing !== undefined) {
        bearing.value = options.bearing
      }

      m.once('moveend', () => {
        isProgrammaticMove = false
        isAnimating.value = false
        resolve()
      })

      m.easeTo(options)
    })
  }

  /**
   * Fit bounds with optional padding
   */
  function fitBounds(bounds: LngLatBoundsLike, options?: FitBoundsOptions): Promise<void> {
    return new Promise((resolve) => {
      const m = mapInstance.map
      if (!m) {
        resolve()
        return
      }

      isProgrammaticMove = true
      isAnimating.value = true

      m.once('moveend', () => {
        isProgrammaticMove = false
        isAnimating.value = false
        // Sync state after bounds fit
        syncStateFromMap()
        resolve()
      })

      m.fitBounds(bounds, options)
    })
  }

  /**
   * Jump to location instantly (no animation)
   */
  function jumpTo(options: { center?: [number, number]; zoom?: number; pitch?: number; bearing?: number }) {
    const m = mapInstance.map
    if (!m) return

    isProgrammaticMove = true

    if (options.center) {
      center.value = { lng: options.center[0], lat: options.center[1] }
    }
    if (options.zoom !== undefined) {
      zoom.value = options.zoom
    }
    if (options.pitch !== undefined) {
      pitch.value = options.pitch
    }
    if (options.bearing !== undefined) {
      bearing.value = options.bearing
    }

    m.jumpTo(options)
    isProgrammaticMove = false
  }

  /**
   * Set center without animation
   */
  function setCenter(lng: number, lat: number) {
    jumpTo({ center: [lng, lat] })
  }

  /**
   * Set zoom without animation
   */
  function setZoom(newZoom: number) {
    jumpTo({ zoom: newZoom })
  }

  /**
   * Get current map bounds
   */
  function getBounds() {
    return mapInstance.map?.getBounds()
  }

  /**
   * Check if a point is within current bounds
   */
  function isInBounds(lng: number, lat: number): boolean {
    const bounds = getBounds()
    if (!bounds) return false
    return bounds.contains([lng, lat])
  }

  /**
   * Stop any ongoing animation
   */
  function stop() {
    mapInstance.map?.stop()
    isProgrammaticMove = false
    isAnimating.value = false
  }

  return {
    // State (reactive, owned by composable)
    center,
    zoom,
    pitch,
    bearing,
    isAnimating,
    isLoaded,

    // Raw map access (for advanced usage)
    map,

    // Methods
    flyTo,
    easeTo,
    fitBounds,
    jumpTo,
    setCenter,
    setZoom,
    getBounds,
    isInBounds,
    stop,

    // Lifecycle
    cleanup: cleanupMapListeners,
  }
}
