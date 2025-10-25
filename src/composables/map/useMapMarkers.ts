import { computed, h, type Component, type ComputedRef, type VNode } from 'vue'
import { useMapBounds, type Marker, type Bounds } from './useMapBounds'

export interface UseMapMarkersOptions<T> {
  data: ComputedRef<T[]>
  markerComponent: Component
  computeMarker: (item: T, index: number) => Marker
  boundsOptions?: {
    padding?: number
    enabled?: boolean
  }
}

export interface UseMapMarkersReturn {
  markers: ComputedRef<Marker[]>
  bounds: ComputedRef<Bounds>
  markerNodes: ComputedRef<VNode[]>
}

export function useMapMarkers<T>(
  options: UseMapMarkersOptions<T>
): UseMapMarkersReturn {
  const markers = computed(() => {
    return options.data.value
      .filter((item: any) => item.lat != null && item.lng != null)
      .map((item, index) => options.computeMarker(item, index))
  })

  const bounds = options.boundsOptions?.enabled === false
    ? computed(() => undefined)
    : useMapBounds(markers, options.boundsOptions?.padding)

  const markerNodes = computed(() => {
    return markers.value.map((marker, index) =>
      h(options.markerComponent, { ...marker, index, key: marker.id })
    )
  })

  return { markers, bounds, markerNodes }
}