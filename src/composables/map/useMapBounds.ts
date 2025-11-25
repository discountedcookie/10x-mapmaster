import { computed, type ComputedRef } from 'vue'

export interface Marker {
  coordinates: [number, number]
  [key: string]: any
}

export type Bounds = [[number, number], [number, number]] | undefined

export function useMapBounds(markers: ComputedRef<Marker[]>, padding = 0.15): ComputedRef<Bounds> {
  return computed(() => {
    if (markers.value.length === 0) return

    const lngs = markers.value.map((m) => m.coordinates[0])
    const lats = markers.value.map((m) => m.coordinates[1])

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    let lngPadding = (maxLng - minLng) * padding
    let latPadding = (maxLat - minLat) * padding

    // For single marker or very small clusters, use minimum padding
    // Single marker (won game): generous padding of 0.5 degrees (~55km)
    // Small cluster: minimum padding of 0.05 degrees (~5.5km)
    const isSingleMarker = markers.value.length === 1
    const minPadding = isSingleMarker ? 0.5 : 0.05

    lngPadding = Math.max(lngPadding, minPadding)
    latPadding = Math.max(latPadding, minPadding)

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ]
  })
}
