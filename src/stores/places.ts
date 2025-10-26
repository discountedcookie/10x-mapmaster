import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { searchPlaces as searchNominatim, extractDescriptors, type NominatimPlace } from '@/lib/places'
import type { RealtimeChannel } from '@supabase/supabase-js'

export interface Place {
    id: string
    name: string
    lat: number
    lng: number
    game_count: number
    descriptors?: any
}

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
                    .from('places')
                    .select('id, name, lat, lng, game_count')
                    .not('lat', 'is', null)
                    .not('lng', 'is', null)
                    .order('name')

                if (fetchError) {
                    throw fetchError
                }

                places.value = (data || []) as Place[]

                // Set up realtime subscription after initial fetch
                setupRealtimeSubscription()
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
                    table: 'places'
                },
                (payload) => {
                    console.log('[Places Store] Realtime event received:', payload.eventType, payload)
                    handleRealtimeChange(payload)
                }
            )
            .subscribe((status) => {
                console.log('[Places Store] Subscription status:', status)
            })
    }

    function handleRealtimeChange(payload: any) {
        const { eventType, new: newRecord, old: oldRecord } = payload

        switch (eventType) {
            case 'INSERT': {
                const place = newRecord as Place
                console.log('[Places Store] INSERT event:', place)
                // Only add if it has valid coordinates and doesn't already exist
                if (place.lat !== null && place.lng !== null) {
                    const exists = places.value.some(p => p.id === place.id)
                    if (!exists) {
                        places.value.push(place)
                        // Sort by name to maintain order
                        places.value.sort((a, b) => a.name.localeCompare(b.name))
                        console.log('[Places Store] Place added. Total places:', places.value.length)
                    } else {
                        console.log('[Places Store] Place already exists, skipping')
                    }
                } else {
                    console.log('[Places Store] Place has null coordinates, skipping')
                }
                break
            }
            case 'UPDATE': {
                const place = newRecord as Place
                const index = places.value.findIndex(p => p.id === place.id)
                console.log('[Places Store] UPDATE event:', place, 'index:', index)

                if (index !== -1) {
                    // Update existing place
                    if (place.lat !== null && place.lng !== null) {
                        places.value[index] = place
                        console.log('[Places Store] Place updated at index', index)
                    } else {
                        // Remove if coordinates became null
                        places.value.splice(index, 1)
                        console.log('[Places Store] Place removed (coordinates became null)')
                    }
                } else if (place.lat !== null && place.lng !== null) {
                    // Add if it wasn't in the list but now has valid coordinates
                    places.value.push(place)
                    places.value.sort((a, b) => a.name.localeCompare(b.name))
                    console.log('[Places Store] Place added via UPDATE. Total places:', places.value.length)
                }
                break
            }
            case 'DELETE': {
                const deletedId = oldRecord.id
                const index = places.value.findIndex(p => p.id === deletedId)
                console.log('[Places Store] DELETE event:', deletedId, 'index:', index)
                if (index !== -1) {
                    places.value.splice(index, 1)
                    console.log('[Places Store] Place removed. Total places:', places.value.length)
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
export type { NominatimPlace }

