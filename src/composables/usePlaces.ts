import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Place {
  id: string
  name: string
  lat: number
  lng: number
  game_count: number
  descriptors: any
}

// Shared state across all components (singleton pattern)
const places = ref<Place[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
let fetchPromise: Promise<void> | null = null

export function usePlaces() {
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
          .from('places')
          .select('id, name, lat, lng, game_count, descriptors')
          .order('name')

        if (fetchError) {
          throw fetchError
        }

        places.value = data || []
      } catch (err) {
        error.value = err instanceof Error ? err.message : 'Failed to fetch places'
        console.error('Error fetching places:', err)
      } finally {
        loading.value = false
        fetchPromise = null
      }
    })()

    return fetchPromise
  }

  return {
    places,
    loading,
    error,
    fetchAllPlaces,
  }
}
