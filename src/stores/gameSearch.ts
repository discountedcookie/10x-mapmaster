import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useGameSessionStore } from './gameSession'

export const useGameSearchStore = defineStore('gameSearch', () => {
  // Cross-store reference (at setup level, not inside computed)
  const sessionStore = useGameSessionStore()

  // State
  const searchResultPlaces = ref<
    Array<{
      id: string
      name: string
      lat: number
      lng: number
    }>
  >([])

  const submittedPlace = ref<{
    name: string
    lat: number
    lng: number
  } | null>(null)

  // Computed - depends on session status
  const isSubmissionPending = computed(() => {
    return sessionStore.isNeedsSubmission && submittedPlace.value !== null
  })

  /**
   * Set search result places from Nominatim
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  function setSearchResultPlaces(places: any[]): void {
    searchResultPlaces.value = places.map((p) => ({
      id: `nominatim-${p.place_id}`,
      name: p.display_name.split(',')[0],
      lat: Number.parseFloat(p.lat),
      lng: Number.parseFloat(p.lon),
    }))
  }

  /**
   * Clear search results
   */
  function clearSearchResultPlaces(): void {
    searchResultPlaces.value = []
  }

  /**
   * Set submitted place for display
   */
  function setSubmittedPlace(place: { name: string; lat: number; lng: number }): void {
    submittedPlace.value = place
    searchResultPlaces.value = []
  }

  /**
   * Clear submitted place
   */
  function clearSubmittedPlace(): void {
    submittedPlace.value = null
  }

  return {
    searchResultPlaces,
    submittedPlace,
    isSubmissionPending,
    setSearchResultPlaces,
    clearSearchResultPlaces,
    setSubmittedPlace,
    clearSubmittedPlace,
  }
})
