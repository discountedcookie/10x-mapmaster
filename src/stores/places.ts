import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { searchPlaces as searchNominatim, extractDescriptors, type NominatimPlace } from '@/lib/places'

export interface Place {
    id: string
    name: string
    lat: number
    lng: number
    game_count: number
    descriptors: any
}

export const usePlacesStore = defineStore('places', () => {
    // State
    const places = ref<Place[]>([])
    const loading = ref(false)
    const error = ref<string | null>(null)
    const searchLoading = ref(false)
    const searchError = ref<string | undefined>(undefined)
    let fetchPromise: Promise<void> | null = null

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
                    .from('places')
                    .select('id, name, lat, lng, game_count, descriptors')
                    .order('name')

                if (fetchError) {
                    throw fetchError
                }

                // Filter out any places with null coordinates
                places.value = (data || []).filter((p): p is Place => p.lat !== null && p.lng !== null) as Place[]
            }
            catch (err) {
                error.value = err instanceof Error ? err.message : 'Failed to fetch places'
                console.error('Error fetching places:', err)
            }
            finally {
                loading.value = false
                fetchPromise = null
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
        }
        catch (err) {
            searchError.value = err instanceof Error ? err.message : 'Failed to search places'
            throw err
        }
        finally {
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
        }
        catch (err) {
            console.warn('Failed to enrich place descriptors:', err)
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
        reset,
    }
})

// Re-export type for convenience
export type { NominatimPlace }

