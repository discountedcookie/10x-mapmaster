import { shallowRef } from 'vue'
import type { PlaceWithScore } from '@/stores/game'

/**
 * Simplified map state that only tracks candidates from active games.
 * Bounds are calculated automatically in MapLayout based on visible markers.
 * Places are fetched directly from the places store.
 */
interface MapState {
  candidates: PlaceWithScore[]
}

const mapState = shallowRef<MapState>({
  candidates: [],
})

export function useMapState() {
  function setCandidates(candidates: PlaceWithScore[]) {
    mapState.value = { candidates }
  }

  function clearMapState() {
    mapState.value = { candidates: [] }
  }

  return {
    mapState,
    setCandidates,
    clearMapState,
  }
}
