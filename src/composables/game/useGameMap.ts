/**
 * Shared composable for game map state and candidates layer management
 * Provides centralized map ref and candidates layer registration
 */

import { computed } from 'vue'
import { useMapCamera, MAP_KEY } from '@/composables/map/useMapCamera'
import { useMapLayersStore } from '@/stores/mapLayers'
import { useGameSessionStore } from '@/stores/gameSession'
import { useGameSearchStore } from '@/stores/gameSearch'
import CandidatesLayer from '@/components/map/CandidatesLayer.vue'

interface PlaceJson {
  id: string
  name: string
  lat: number | null
  lng: number | null
}

interface CandidateLike {
  id: string
  name: string
  lat: number
  lng: number
  confidence?: number | null
  description_similarity?: number | null
  affirmed_trait_similarity?: number | null
  denied_trait_similarity?: number | null
  geographic_distance?: number | null
  // Optional geometry for 3D polygons
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  geometry?: any
}

export function useGameMap() {
  const baseSessionStore = useGameSessionStore()
  // Narrow the game session store locally to avoid deep Supabase+Pinia generics
  const sessionStore = baseSessionStore as unknown as {
    isWon: boolean
    session: { place: unknown; candidates: unknown } | null
  }

  const searchStore = useGameSearchStore()
  const mapLayersStore = useMapLayersStore()
  const camera = useMapCamera()

  const displayCandidates = computed<CandidateLike[]>(() => {
    // Winner state - show final place from session.place
    const place = sessionStore.session?.place as PlaceJson | null | undefined
    if (sessionStore.isWon && place && place.lat != null && place.lng != null) {
      return [
        {
          id: place.id,
          name: place.name,
          lat: place.lat,
          lng: place.lng,
          confidence: 1,
          description_similarity: 1,
          affirmed_trait_similarity: null,
          denied_trait_similarity: null,
          geographic_distance: null,
        },
      ]
    }

    // Submission pending - show submitted place as winner
    if (searchStore.isSubmissionPending && searchStore.submittedPlace) {
      return [
        {
          id: 'submitted',
          name: searchStore.submittedPlace.name,
          lat: searchStore.submittedPlace.lat,
          lng: searchStore.submittedPlace.lng,
          confidence: 1,
          description_similarity: 1,
          affirmed_trait_similarity: null,
          denied_trait_similarity: null,
          geographic_distance: null,
        },
      ]
    }

    // During search - show Nominatim results as candidates
    if (searchStore.searchResultPlaces.length > 0) {
      return searchStore.searchResultPlaces.map((p) => ({
        id: p.id,
        name: p.name,
        lat: p.lat,
        lng: p.lng,
        confidence: 0.5,
        description_similarity: 0.5,
        affirmed_trait_similarity: null,
        denied_trait_similarity: null,
        geographic_distance: null,
      }))
    }

    // Default: backend-provided candidates from session.candidates JSON
    const backendCandidates = sessionStore.session?.candidates as CandidateLike[] | undefined
    return backendCandidates ?? []
  })

  const hideCircles = computed(() => {
    const first = displayCandidates.value[0]
    return !!first?.geometry
  })

  function registerCandidatesLayer(highlightedId?: string) {
    if (displayCandidates.value.length > 0) {
      mapLayersStore.setLayers([
        {
          key: 'candidates',
          component: CandidatesLayer,
          props: {
            candidates: displayCandidates.value,
            mapKey: MAP_KEY,
            hideCircles: hideCircles.value,
            highlightedId: highlightedId,
          },
        },
      ])
    }
  }

  return {
    camera,
    displayCandidates,
    hideCircles,
    registerCandidatesLayer,
  }
}
