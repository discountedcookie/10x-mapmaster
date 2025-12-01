/**
 * Place utilities - unified exports
 *
 * Clean barrel exports for all place-related functionality:
 * - Nominatim API client (search, geocoding, formatting)
 * - Type definitions
 */

// Response caching system for API optimization
interface CacheEntry<T> {
  data: T
  timestamp: number
  ttl: number
}

class APICache {
  private cache = new Map<string, CacheEntry<any>>()

  set<T>(key: string, data: T, ttlMs: number): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttlMs,
    })
  }

  get<T>(key: string): T | null {
    const entry = this.cache.get(key)
    if (!entry) return null

    if (Date.now() - entry.timestamp > entry.ttl) {
      this.cache.delete(key)
      return null
    }

    return entry.data
  }

  clear(): void {
    this.cache.clear()
  }

  // Clean expired entries periodically
  cleanup(): void {
    const now = Date.now()
    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > entry.ttl) {
        this.cache.delete(key)
      }
    }
  }
}

// Global cache instance
export const apiCache = new APICache()

// Rate limiting (shared across all place APIs)
let lastRequestTime = 0
const MIN_REQUEST_INTERVAL = 1000

export async function waitForRateLimit(): Promise<void> {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime

  if (timeSinceLastRequest < MIN_REQUEST_INTERVAL) {
    await new Promise((resolve) => setTimeout(resolve, MIN_REQUEST_INTERVAL - timeSinceLastRequest))
  }

  lastRequestTime = Date.now()
}

// Cache wrapper for API calls
export async function withCache<T>(
  key: string,
  function_: () => Promise<T>,
  ttlMs: number = 300_000 // 5 minutes default
): Promise<T> {
  const cached = apiCache.get<T>(key)
  if (cached) {
    return cached
  }

  const result = await function_()
  apiCache.set(key, result, ttlMs)
  return result
}

// Cleanup cache every 10 minutes
if (globalThis.window !== undefined) {
  setInterval(() => apiCache.cleanup(), 600_000)
}

// Nominatim client
export {
  searchPlaces,
  queryPlaceWithRetry,
  extractDescriptors,
  type NominatimPlace,
  type JSONPlace,
  type AddressDetails,
  type ExtraTags,
} from './nominatim'

// Embedding text generation (moved from nominatim.ts)
export function generatePlaceEmbeddingText(place: {
  name: string
  descriptors: any
  wikipedia_summary?: string | null
}): string {
  const parts: string[] = [place.name]
  const desc = place.descriptors
  const extension = desc.extratags || {}

  // HEIGHT/ELEVATION (critical for discrimination!)
  if (desc.elevation_meters) {
    parts.push(`Elevation: ${desc.elevation_meters} meters`)
  }
  if (desc.height_meters) {
    parts.push(`Height: ${desc.height_meters} meters`)
  }

  // Type and category
  if (desc.type) parts.push(`Type: ${desc.type}`)
  if (desc.class) parts.push(`Category: ${desc.class}`)

  // Extratags
  if (extension.natural) parts.push(`Natural feature: ${extension.natural}`)
  if (extension.year_of_construction) parts.push(`Built: ${extension.year_of_construction}`)
  if (extension.architect) parts.push(`Architect: ${extension.architect}`)
  if (extension.building) parts.push(`Building type: ${extension.building}`)

  // Wikipedia summary (NEW - rich context!)
  if (place.wikipedia_summary) {
    // Take first 200 chars of summary
    const summary = place.wikipedia_summary.slice(0, 200).trim()
    parts.push(summary)
  }

  // Location - prefer English names for embeddings
  // Use name:en from extratags if available, otherwise use country_code
  const cityName = extension['name:en'] || desc.address?.city
  const countryName = extension['country:en'] || desc.address?.country

  // Only include if name appears to be in Latin alphabet (English-friendly)
  // This filters out Greek, Chinese, Arabic, etc. characters
  // Matches: Basic Latin (ASCII), Latin-1 Supplement, Latin Extended-A/B, Latin Extended Additional
  const isLatinText = (text: string) => /^[A-Za-z\u00C0-\u024F\u1E00-\u1EFF\s-]+$/.test(text)

  if (cityName && isLatinText(cityName)) {
    parts.push(`City: ${cityName}`)
  }
  if (countryName && isLatinText(countryName)) {
    parts.push(`Country: ${countryName}`)
  } else if (desc.country_code) {
    // Fallback to country code if localized name
    parts.push(`Country code: ${desc.country_code.toUpperCase()}`)
  }

  return parts.join('. ')
}

// Types
export type { PlaceDescriptors } from './types'
