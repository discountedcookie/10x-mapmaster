import { ref, watch, onUnmounted } from 'vue'
import type { MapInstance } from '@indoorequal/vue-maplibre-gl'

export interface MapCenter {
  lng: number
  lat: number
}

/**
 * Composable for tracking map center position
 *
 * Automatically sets up and cleans up map event listeners to track
 * the center position. Updates reactively when the map moves.
 *
 * @param mapInstance - The map instance from useMap()
 * @returns Reactive ref containing current map center {lng, lat}
 */
export function useMapCenterTracking(mapInstance: MapInstance) {
  const mapCenter = ref<MapCenter>({ lng: 0, lat: 0 })

  function updateMapCenter() {
    const map = mapInstance.map
    if (!map) return
    const center = map.getCenter()
    mapCenter.value = { lng: center.lng, lat: center.lat }
  }

  function setupListener() {
    const map = mapInstance.map
    if (!map) return

    // Initial sync
    updateMapCenter()

    // Update on map movement
    map.on('move', updateMapCenter)
  }

  function cleanupListener() {
    const map = mapInstance.map
    if (!map) return

    map.off('move', updateMapCenter)
  }

  // Setup listener when map is loaded
  watch(
    () => mapInstance.isLoaded,
    (isLoaded) => {
      if (isLoaded) {
        setupListener()
      }
    },
    { immediate: true }
  )

  // Cleanup on unmount
  onUnmounted(() => {
    cleanupListener()
  })

  return {
    mapCenter,
    cleanup: cleanupListener,
  }
}
