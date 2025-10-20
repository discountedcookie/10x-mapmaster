import { ref } from 'vue'
import * as Nominatim from 'nominatim-ts'

// Simplified type to avoid deep instantiation issues with nominatim-ts
export interface NominatimPlace {
  place_id: string | number
  display_name: string
  lat: string
  lon: string
  type: string
  class: string
  address?: Record<string, any>
  extratags?: Record<string, any>
}

// Rate limiting: 1 request per second
let lastRequestTime = 0
const MIN_REQUEST_INTERVAL = 1000

async function waitForRateLimit() {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime
  if (timeSinceLastRequest < MIN_REQUEST_INTERVAL) {
    await new Promise(resolve => setTimeout(resolve, MIN_REQUEST_INTERVAL - timeSinceLastRequest))
  }
  lastRequestTime = Date.now()
}

export function useNominatim() {
  const loading = ref(false)
  const error = ref<string | undefined>(undefined)

  async function search(query: string): Promise<NominatimPlace[]> {
    if (!query.trim()) {
      return []
    }

    try {
      loading.value = true
      error.value = undefined

      await waitForRateLimit()

      const results = await Nominatim.search({
        q: query,
        format: 'json',
        addressdetails: 1,
        extratags: 1,
        limit: 5,
      })

      return results as NominatimPlace[]
    }
    catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to search places'
      throw err
    }
    finally {
      loading.value = false
    }
  }

  function extractDescriptors(place: NominatimPlace): Record<string, any> {
    return {
      country_code: place.address?.country_code,
      type: place.type,
      class: place.class,
      address: place.address,
      extratags: place.extratags,
    }
  }

  return {
    loading,
    error,
    search,
    extractDescriptors,
  }
}
