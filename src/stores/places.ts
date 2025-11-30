import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import {
  searchPlaces as searchNominatim,
  extractDescriptors,
  type NominatimPlace,
} from '@/lib/places'
import type { RealtimeChannel } from '@supabase/supabase-js'
import type { Tables } from '@/types/database'

export type Place = Tables<'places_with_geometry'>

export const usePlacesStore = defineStore('places', () => {
  // State
  const places = ref<Place[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const searchLoading = ref(false)
  const searchError = ref<string | undefined>(undefined)
  let fetchPromise: Promise<void> | null = null
  let realtimeChannel: RealtimeChannel | null = null

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

        // Set up realtime subscription after initial fetch
        setupRealtimeSubscription()
      } catch (error_) {
        error.value = error_ instanceof Error ? error_.message : 'Failed to fetch places'
      } finally {
        loading.value = false
        fetchPromise = null
      }
    })()

    return fetchPromise
  }

  function setupRealtimeSubscription() {
    // Clean up existing subscription if any
    if (realtimeChannel) {
      supabase.removeChannel(realtimeChannel)
    }

    // Subscribe to changes in the places table
    realtimeChannel = supabase
      .channel('places-changes')
      .on(
        'postgres_changes',
        {
          event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
          schema: 'public',
          table: 'places',
        },
        (payload) => {
          handleRealtimeChange(payload)
        }
      )
      .subscribe((_status) => {
        // Subscription status updated
      })
  }

  async function handleRealtimeChange(payload: any) {
    const { eventType, new: newRecord, old: oldRecord } = payload

    switch (eventType) {
      case 'INSERT':
      case 'UPDATE': {
        // Refetch the place from view to get geometry
        const { data } = await supabase
          .from('places_with_geometry')
          .select('*')
          .eq('id', newRecord.id)
          .single()

        if (data) {
          // Cast through any to avoid TypeScript deep instantiation error with Supabase types
          const placeData = data as any as Place
          const index = places.value.findIndex((p) => p.id === placeData.id)
          if (index !== -1) {
            ;(places.value as any)[index] = placeData
          } else {
            ;(places.value as any).push(placeData)
            places.value.sort((a, b) => (a.name ?? '').localeCompare(b.name ?? ''))
          }
        }
        break
      }
      case 'DELETE': {
        const deletedId = oldRecord.id
        const index = places.value.findIndex((p) => p.id === deletedId)
        if (index !== -1) {
          places.value.splice(index, 1)
        }
        break
      }
    }
  }

  function unsubscribeRealtime() {
    if (realtimeChannel) {
      supabase.removeChannel(realtimeChannel)
      realtimeChannel = null
    }
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

  /**
   * Enriches place descriptors with elevation and height data
   * Call this before saving a new place to the database
   */
  async function enrichDescriptors(
    lat: number,
    lng: number,
    descriptors: Record<string, any>
  ): Promise<Record<string, any>> {
    try {
      // Dynamically import enrichment modules (browser-compatible)
      const { enrichWithElevation, enrichWithHeight } = await import('@/lib/places')

      // Enrich with elevation (natural features)
      const elevation = await enrichWithElevation(lat, lng, descriptors as any)

      // Enrich with height (buildings)
      const height = await enrichWithHeight(lat, lng, descriptors as any)

      return {
        ...descriptors,
        ...(elevation !== null && { elevation_meters: elevation }),
        ...(height !== null && { height_meters: height }),
        enrichment_timestamp: new Date().toISOString(),
      }
    } catch (error_) {
      console.warn('Failed to enrich place descriptors:', error_)
      // Return original descriptors if enrichment fails
      return descriptors
    }
  }

  function reset() {
    places.value = []
    loading.value = false
    error.value = null
    searchLoading.value = false
    searchError.value = undefined
    fetchPromise = null
    unsubscribeRealtime()
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
    enrichDescriptors,
    extractDescriptors: (place: NominatimPlace) => extractDescriptors(place),
    unsubscribeRealtime,
    reset,
  }
})

// Re-export type for convenience

export { type NominatimPlace } from '@/lib/places'
