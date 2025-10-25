import { computed, type ComputedRef } from 'vue'

export interface Marker {
  coordinates: [number, number]
  [key: string]: any
}

export type Bounds = [[number, number], [number, number]] | undefined

export function useMapBounds(
  markers: ComputedRef<Marker[]>,
  padding = 0.15
): ComputedRef<Bounds> {
  return computed(() => {
    if (markers.value.length === 0) return undefined

    const lngs = markers.value.map(m => m.coordinates[0])
    const lats = markers.value.map(m => m.coordinates[1])

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    const lngPadding = (maxLng - minLng) * padding
    const latPadding = (maxLat - minLat) * padding

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ]
  })
}