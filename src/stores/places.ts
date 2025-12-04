import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { searchPlaces as searchNominatim, type NominatimPlace } from '@/lib/places'
import type { Tables } from '@/types/database'

export type Place = Tables<'places_with_geometry'>

export const usePlacesStore = defineStore('places', () => {
  // State
  const places = ref<Place[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const searchLoading = ref(false)
  const searchError = ref<string | null>(null)
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
    error.value = null

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
      searchError.value = null

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
    error.value = null
    searchLoading.value = false
    searchError.value = null
    fetchPromise = undefined
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
    reset,
  }
})

// Re-export type for convenience

export { type NominatimPlace } from '@/lib/places'
