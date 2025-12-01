import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import {
  searchPlaces as searchNominatim,
  extractDescriptors,
  type NominatimPlace,
} from '@/lib/places'
import type { Tables } from '@/types/database'

export type Place = Tables<'places_with_geometry'>

export const usePlacesStore = defineStore('places', () => {
  // State
  const places = ref<Place[]>([])
  const loading = ref(false)
  const error = ref<string | undefined>()
  const searchLoading = ref(false)
  const searchError = ref<string | undefined>()
  let fetchPromise: Promise<void> | undefined

  // Actions
  async function fetchAllPlaces() {
    // If already loaded, don't fetch again
    if (places.value.length > 0) {
      return
    }

    // If already fetching, return the existing promise
    if (fetchPromise) {
      return fetchPromise
    }

    loading.value = true
    error.value = undefined

    fetchPromise = (async () => {
      try {
        const { data, error: fetchError } = await supabase
          .from('places_with_geometry')
          .select('*')
          .order('name')

        if (fetchError) {
          throw fetchError
        }

        places.value = data || []
      } catch (error_) {
        error.value = error_ instanceof Error ? error_.message : 'Failed to fetch places'
      } finally {
        loading.value = false
        fetchPromise = undefined
      }
    })()

    return fetchPromise
  }

  async function searchPlaces(query: string): Promise<NominatimPlace[]> {
    try {
      searchLoading.value = true
      searchError.value = undefined

      const results = await searchNominatim(query, { limit: 5 })
      return results
    } catch (error_) {
      searchError.value = error_ instanceof Error ? error_.message : 'Failed to search places'
      throw error_
    } finally {
      searchLoading.value = false
    }
  }

  function reset() {
    places.value = []
    loading.value = false
    error.value = undefined
    searchLoading.value = false
    searchError.value = undefined
    fetchPromise = undefined
  }

  /**
   * Unsubscribe from realtime updates
   * Called by useRealtimePlaces composable
   */
  function unsubscribeRealtime() {
    // Realtime subscription is now managed by useRealtimePlaces composable
    // This function is kept for backward compatibility with HomeView.vue
  }

  return {
    // State
    places,
    loading,
    error,
    searchLoading,
    searchError,

    // Actions
    fetchAllPlaces,
    searchPlaces,
    extractDescriptors: (place: NominatimPlace) => extractDescriptors(place),
    unsubscribeRealtime,
    reset,
  }
})

// Re-export type for convenience

export { type NominatimPlace } from '@/lib/places'
