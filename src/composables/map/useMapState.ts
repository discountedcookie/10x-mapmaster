import { shallowRef } from 'vue'

export type Bounds = [[number, number], [number, number]] | undefined

interface Place {
  id: string
  name: string
  lat: number | null
  lng: number | null
  game_count?: number
}

interface MapState {
  bounds: Bounds
  places: Place[]
}

const mapState = shallowRef<MapState>({
  bounds: undefined,
  places: []
})

export function useMapState() {
  function setMapState(
    bounds: Bounds,
    places: Place[]
  ) {
    mapState.value = { bounds, places }
  }

  function clearMapState() {
    mapState.value = {
      bounds: undefined,
      places: []
    }
  }

  return {
    mapState,
    setMapState,
    clearMapState
  }
}