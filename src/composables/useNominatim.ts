import { ref } from 'vue'
import { searchPlaces, extractDescriptors, type NominatimPlace } from '@/lib/places'

// Re-export the type for backwards compatibility
export type { NominatimPlace }

export function useNominatim() {
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)

  async function search(query: string): Promise<NominatimPlace[]> {
    try {
      loading.value = true
      error.value = undefined

      const results = await searchPlaces(query, { limit: 5 })
      return results
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to search places'
      throw err
    }
    finally {
      loading.value = false
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
      const elevation = await enrichWithElevation(lat, lng, descriptors)
      
      // Enrich with height (buildings)
      const height = await enrichWithHeight(lat, lng, descriptors)

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

  return {
    loading,
    error,
    search,
    extractDescriptors: (place: NominatimPlace) => extractDescriptors(place),
    enrichDescriptors,
  }
}
