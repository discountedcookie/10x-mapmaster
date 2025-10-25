import { ref, shallowRef, type Component, type VNode } from 'vue'

export type Bounds = [[number, number], [number, number]] | undefined

interface MapState {
  bounds: Bounds
  markerNodes: VNode[]
}

const mapState = shallowRef<MapState>({
  bounds: undefined,
  markerNodes: []
})

export function useMapState() {
  function setMapState(bounds: Bounds, markerNodes: VNode[]) {
    mapState.value = { bounds, markerNodes }
  }

  function clearMapState() {
    mapState.value = { bounds: undefined, markerNodes: [] }
  }

  return {
    mapState,
    setMapState,
    clearMapState
  }
}