import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { usePlacesStore, type Place, type NominatimPlace } from '@/stores/places'

// Mock Supabase - use factory to avoid hoisting issues
vi.mock('@/lib/supabase', () => {
  const mockSelect = vi.fn()
  const mockOrder = vi.fn()
  const mockFrom = vi.fn()
  const mockChannel = vi.fn(() => ({
    on: vi.fn(function (this: any) {
      return this
    }),
    subscribe: vi.fn(() => {}),
  }))
  const mockRemoveChannel = vi.fn()

  return {
    supabase: {
      from: mockFrom,
      channel: mockChannel,
      removeChannel: mockRemoveChannel,
    },
    mockSelect,
    mockOrder,
    mockFrom,
    mockChannel,
    mockRemoveChannel,
  }
})

// Mock lib/places functions
vi.mock('@/lib/places', () => {
  const mockSearchNominatim = vi.fn()
  const mockExtractDescriptors = vi.fn()

  return {
    searchPlaces: mockSearchNominatim,
    extractDescriptors: mockExtractDescriptors,
    mockSearchNominatim,
    mockExtractDescriptors,
  }
})

const { mockSelect, mockOrder, mockFrom } = (await import('@/lib/supabase')) as any
const { mockSearchNominatim } = (await import('@/lib/places')) as any

describe('usePlacesStore', () => {
  let store: ReturnType<typeof usePlacesStore>

  const mockPlaces: Place[] = [
    {
      id: 'place-1',
      name: 'Paris',
      lat: 48.8566,
      lng: 2.3522,
      times_encountered: 10,
      descriptors: { type: 'city' },
    },
    {
      id: 'place-2',
      name: 'London',
      lat: 51.5074,
      lng: -0.1278,
      times_encountered: 8,
      descriptors: { type: 'city' },
    },
  ]

  beforeEach(() => {
    setActivePinia(createPinia())
    store = usePlacesStore()
    vi.clearAllMocks()

    // Suppress console errors/warnings (they're intentional for error handling tests)
    vi.spyOn(console, 'error').mockImplementation(() => {})
    vi.spyOn(console, 'warn').mockImplementation(() => {})
    vi.spyOn(console, 'log').mockImplementation(() => {})

    // Default mock setup - chain includes .not() calls
    const mockNot = vi.fn()
    mockNot.mockReturnValue({
      not: mockNot,
      order: mockOrder.mockResolvedValue({
        data: mockPlaces,
        error: null,
      }),
    })

    mockFrom.mockReturnValue({
      select: mockSelect.mockReturnValue(mockNot()),
    })
  })

  describe('fetchAllPlaces', () => {
    it('should fetch places from Supabase', async () => {
      await store.fetchAllPlaces()

      expect(store.places).toEqual(mockPlaces)
    })

    it('should set loading state during fetch', async () => {
      expect(store.loading).toBe(false)

      const fetchPromise = store.fetchAllPlaces()
      expect(store.loading).toBe(true)

      await fetchPromise
      expect(store.loading).toBe(false)
    })

    it('should not fetch if places already loaded', async () => {
      // First fetch
      await store.fetchAllPlaces()
      expect(mockFrom).toHaveBeenCalledTimes(1)

      // Second fetch should be skipped
      await store.fetchAllPlaces()
      expect(mockFrom).toHaveBeenCalledTimes(1)
      expect(store.places).toEqual(mockPlaces)
    })

    it('should handle errors gracefully', async () => {
      const error = new Error('Database connection failed')
      mockOrder.mockRejectedValueOnce(error)

      await store.fetchAllPlaces()

      expect(store.error).toBe('Database connection failed')
      expect(store.places).toEqual([])
      expect(store.loading).toBe(false)
    })

    it('should handle non-Error exceptions', async () => {
      mockOrder.mockRejectedValueOnce('String error')

      await store.fetchAllPlaces()

      expect(store.error).toBe('Failed to fetch places')
      expect(store.places).toEqual([])
    })

    it('should clear previous error on successful fetch', async () => {
      // First fetch fails
      mockOrder.mockRejectedValueOnce(new Error('Error'))
      await store.fetchAllPlaces()
      expect(store.error).toBe('Error')

      // Reset store and mock for second fetch
      store.reset()
      mockOrder.mockResolvedValueOnce({
        data: mockPlaces,
        error: null,
      })

      // Second fetch succeeds
      await store.fetchAllPlaces()

      expect(store.error).toBeNull()
      expect(store.places).toEqual(mockPlaces)
    })

    it('should reuse existing fetch promise if already fetching', async () => {
      // Start two fetches simultaneously
      const promise1 = store.fetchAllPlaces()
      const promise2 = store.fetchAllPlaces()

      // Both should resolve
      await Promise.all([promise1, promise2])

      // But only one DB call should be made
      expect(mockFrom).toHaveBeenCalledTimes(1)
    })

    it('should handle empty results', async () => {
      mockOrder.mockResolvedValueOnce({
        data: [],
        error: null,
      })

      await store.fetchAllPlaces()

      expect(store.places).toEqual([])
      expect(store.error).toBeNull()
    })

    it('should handle null data from Supabase', async () => {
      mockOrder.mockResolvedValueOnce({
        data: null,
        error: null,
      })

      await store.fetchAllPlaces()

      expect(store.places).toEqual([])
    })

    it('should set loading to false even if fetch throws', async () => {
      mockOrder.mockRejectedValueOnce(new Error('Network error'))

      await store.fetchAllPlaces()

      expect(store.loading).toBe(false)
    })
  })

  describe('addPlace', () => {
    it('should add a place to the store', () => {
      const newPlace: Place = {
        id: 'place-3',
        name: 'Berlin',
        lat: 52.52,
        lng: 13.405,
        times_encountered: 5,
        descriptors: { type: 'city' },
      }

      store.addPlace(newPlace)

      expect(store.places).toContainEqual(newPlace)
    })

    it('should maintain sort order by name when adding', () => {
      // Pre-populate with some places
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
        {
          id: 'place-2',
          name: 'Paris',
          lat: 48.8566,
          lng: 2.3522,
          times_encountered: 10,
          descriptors: {},
        },
      ]

      const newPlace: Place = {
        id: 'place-3',
        name: 'London',
        lat: 51.5074,
        lng: -0.1278,
        times_encountered: 8,
        descriptors: { type: 'city' },
      }

      store.addPlace(newPlace)

      expect(store.places.map((p) => p.name)).toEqual(['Berlin', 'London', 'Paris'])
    })
  })

  describe('updatePlace', () => {
    it('should update an existing place', () => {
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
      ]

      const updatedPlace: Place = {
        id: 'place-1',
        name: 'Berlin Updated',
        lat: 52.53,
        lng: 13.41,
        times_encountered: 10,
        descriptors: { type: 'capital' },
      }

      store.updatePlace('place-1', updatedPlace)

      expect(store.places[0]).toEqual(updatedPlace)
    })

    it('should do nothing if place not found', () => {
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
      ]

      const updatedPlace: Place = {
        id: 'place-2',
        name: 'Paris',
        lat: 48.8566,
        lng: 2.3522,
        times_encountered: 10,
        descriptors: {},
      }

      store.updatePlace('place-2', updatedPlace)

      expect(store.places).toHaveLength(1)
      expect(store.places[0].id).toBe('place-1')
    })

    it('should maintain sort order by name when updating', () => {
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
        {
          id: 'place-2',
          name: 'Paris',
          lat: 48.8566,
          lng: 2.3522,
          times_encountered: 10,
          descriptors: {},
        },
      ]

      // Update Berlin to Zurich - should move to end
      const updatedPlace: Place = {
        id: 'place-1',
        name: 'Zurich',
        lat: 47.3769,
        lng: 8.5417,
        times_encountered: 5,
        descriptors: {},
      }

      store.updatePlace('place-1', updatedPlace)

      expect(store.places.map((p) => p.name)).toEqual(['Paris', 'Zurich'])
    })
  })

  describe('removePlace', () => {
    it('should remove an existing place by id', () => {
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
        {
          id: 'place-2',
          name: 'Paris',
          lat: 48.8566,
          lng: 2.3522,
          times_encountered: 10,
          descriptors: {},
        },
      ]

      store.removePlace('place-1')

      expect(store.places).toHaveLength(1)
      expect(store.places[0].id).toBe('place-2')
    })

    it('should do nothing if place not found', () => {
      store.places = [
        {
          id: 'place-1',
          name: 'Berlin',
          lat: 52.52,
          lng: 13.405,
          times_encountered: 5,
          descriptors: {},
        },
      ]

      store.removePlace('place-999')

      expect(store.places).toHaveLength(1)
      expect(store.places[0].id).toBe('place-1')
    })
  })

  describe('searchPlaces', () => {
    const mockNominatimPlace: NominatimPlace = {
      place_id: 123,
      display_name: 'Paris, France',
      lat: '48.8566',
      lon: '2.3522',
      type: 'city',
      class: 'place',
      importance: 0.9,
    } as NominatimPlace

    it('should search for places successfully', async () => {
      mockSearchNominatim.mockResolvedValueOnce([mockNominatimPlace])

      const results = await store.searchPlaces('Paris')

      expect(results).toEqual([mockNominatimPlace])
      expect(store.searchLoading).toBe(false)
      expect(store.searchError).toBeNull()
    })

    it('should set loading state during search', async () => {
      mockSearchNominatim.mockImplementation(() => {
        expect(store.searchLoading).toBe(true)
        return Promise.resolve([mockNominatimPlace])
      })

      await store.searchPlaces('Paris')

      expect(store.searchLoading).toBe(false)
    })

    it('should handle search errors', async () => {
      mockSearchNominatim.mockRejectedValueOnce(new Error('Network error'))

      await expect(store.searchPlaces('Paris')).rejects.toThrow('Network error')
      expect(store.searchError).toBe('Network error')
      expect(store.searchLoading).toBe(false)
    })

    it('should handle non-Error exceptions', async () => {
      mockSearchNominatim.mockRejectedValueOnce('String error')

      await expect(store.searchPlaces('Paris')).rejects.toBe('String error')
      expect(store.searchError).toBe('Failed to search places')
    })
  })
})
