import { beforeEach, describe, expect, it, vi } from 'vitest'
import { searchPlaces, extractDescriptors, type NominatimPlace } from '@/lib/places/nominatim'

// Mock nominatim-ts - use factory to avoid hoisting issues
vi.mock('nominatim-ts', () => {
  const mockNominatimSearch = vi.fn()
  return {
    search: mockNominatimSearch,
    mockNominatimSearch,
  }
})

// Mock @/lib/places with proper partial mock using importOriginal
vi.mock('@/lib/places', async () => {
  const actual = await vi.importActual('@/lib/places')
  return {
    ...actual,
    waitForRateLimit: vi.fn().mockResolvedValue(),
  }
})

const { mockNominatimSearch } = (await import('nominatim-ts')) as any

describe('Nominatim utilities', () => {
  const mockPlace: NominatimPlace = {
    place_id: 123,
    display_name: 'Paris, France',
    lat: '48.8566',
    lon: '2.3522',
    type: 'city',
    class: 'place',
    importance: 0.9,
    address: {
      city: 'Paris',
      country: 'France',
      country_code: 'fr',
    },
    extratags: {
      population: '2161000',
    },
  } as NominatimPlace

  beforeEach(() => {
    vi.clearAllMocks()
    // Suppress console logs/errors in tests
    vi.spyOn(console, 'log').mockImplementation(() => {})
    vi.spyOn(console, 'error').mockImplementation(() => {})
    vi.spyOn(console, 'warn').mockImplementation(() => {})
  })

  describe('searchPlaces', () => {
    it('should search for places with default options and English language', async () => {
      mockNominatimSearch.mockResolvedValueOnce([mockPlace])

      const results = await searchPlaces('Paris')

      expect(mockNominatimSearch).toHaveBeenCalledWith({
        q: 'Paris',
        format: 'json',
        addressdetails: 1,
        extratags: 1,
        limit: 5,
        acceptlanguage: 'en', // Always request English for embeddings
      })
      expect(results).toEqual([mockPlace])
    })

    it('should accept custom limit', async () => {
      mockNominatimSearch.mockResolvedValueOnce([mockPlace])

      await searchPlaces('Paris', { limit: 10 })

      expect(mockNominatimSearch).toHaveBeenCalledWith(
        expect.objectContaining({
          limit: 10,
          acceptlanguage: 'en', // Always request English
        })
      )
    })

    it('should accept custom addressdetails option', async () => {
      mockNominatimSearch.mockResolvedValueOnce([mockPlace])

      await searchPlaces('Paris', { addressdetails: 0 })

      expect(mockNominatimSearch).toHaveBeenCalledWith(
        expect.objectContaining({ addressdetails: 0 })
      )
    })

    it('should accept custom extratags option', async () => {
      mockNominatimSearch.mockResolvedValueOnce([mockPlace])

      await searchPlaces('Paris', { extratags: 0 })

      expect(mockNominatimSearch).toHaveBeenCalledWith(expect.objectContaining({ extratags: 0 }))
    })

    it('should return empty array for empty query', async () => {
      const results = await searchPlaces('')

      expect(mockNominatimSearch).not.toHaveBeenCalled()
      expect(results).toEqual([])
    })

    it('should return empty array for whitespace query', async () => {
      const results = await searchPlaces('   ')

      expect(mockNominatimSearch).not.toHaveBeenCalled()
      expect(results).toEqual([])
    })

    it('should handle empty results', async () => {
      mockNominatimSearch.mockResolvedValueOnce([])

      const results = await searchPlaces('Nonexistent Place')

      expect(results).toEqual([])
    })

    it('should use cache for subsequent calls with same parameters', async () => {
      mockNominatimSearch.mockResolvedValueOnce([mockPlace])

      // First call should hit the API
      const result1 = await searchPlaces('London')
      expect(mockNominatimSearch).toHaveBeenCalledTimes(1)

      // Second call with same parameters should use cache
      mockNominatimSearch.mockClear()
      const result2 = await searchPlaces('London')

      // Mock should not be called again (result from cache)
      expect(mockNominatimSearch).not.toHaveBeenCalled()
      expect(result2).toEqual(result1)
    })
  })

  // Note: queryPlaceWithRetry is only used in seed scripts, not in the main app
  // It's tested implicitly through integration tests of the seed scripts
  // We don't need unit tests for complex retry logic that's only used offline

  describe('extractDescriptors', () => {
    it('should extract all descriptor fields', () => {
      const result = extractDescriptors(mockPlace)

      expect(result).toEqual({
        lat: 48.8566,
        lng: 2.3522,
        country_code: 'fr',
        type: 'city',
        class: 'place',
        address: mockPlace.address,
        extratags: mockPlace.extratags,
      })
    })

    it('should handle missing address fields', () => {
      const placeWithoutCountry: NominatimPlace = {
        ...mockPlace,
        address: {} as any,
      }

      const result = extractDescriptors(placeWithoutCountry)

      expect(result.country_code).toBe('')
    })

    it('should parse lat/lng as numbers', () => {
      const result = extractDescriptors(mockPlace)

      expect(typeof result.lat).toBe('number')
      expect(typeof result.lng).toBe('number')
    })
  })
})
