import { ref, shallowRef, type Component, type VNode } from 'vue'

export type Bounds = [[number, number], [number, number]] | undefined

interface MapState {
  bounds: Bounds
  markerNodes: VNode[]
  placesGeoJson?: any
  isBrowseMode?: boolean
}

const mapState = shallowRef<MapState>({
  bounds: undefined,
  markerNodes: [],
  placesGeoJson: null,
  isBrowseMode: false
})

export function useMapState() {
  function setMapState(
    bounds: Bounds,
    markerNodes: VNode[],
    placesGeoJson?: any,
    isBrowseMode?: boolean
  ) {
    mapState.value = { bounds, markerNodes, placesGeoJson, isBrowseMode }
  }

  function clearMapState() {
    mapState.value = {
      bounds: undefined,
      markerNodes: [],
      placesGeoJson: null,
      isBrowseMode: false
    }
  }

  return {
    mapState,
    setMapState,
    clearMapState
  }
}