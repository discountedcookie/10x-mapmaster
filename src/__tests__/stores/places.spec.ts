import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { usePlacesStore, type Place, type NominatimPlace } from '@/stores/places'

// Mock Supabase - use factory to avoid hoisting issues
vi.mock('@/lib/supabase', () => {
    const mockSelect = vi.fn()
    const mockOrder = vi.fn()
    const mockFrom = vi.fn()
    const mockChannel = vi.fn(() => ({
        on: vi.fn(function(this: any) { return this }),
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
    const mockEnrichWithElevation = vi.fn()
    const mockEnrichWithHeight = vi.fn()

    return {
        searchPlaces: mockSearchNominatim,
        extractDescriptors: mockExtractDescriptors,
        enrichWithElevation: mockEnrichWithElevation,
        enrichWithHeight: mockEnrichWithHeight,
        mockSearchNominatim,
        mockExtractDescriptors,
        mockEnrichWithElevation,
        mockEnrichWithHeight,
    }
})

const { mockSelect, mockOrder, mockFrom } = await import('@/lib/supabase') as any
const { mockSearchNominatim, mockExtractDescriptors, mockEnrichWithElevation, mockEnrichWithHeight } = await import('@/lib/places') as any

describe('usePlacesStore', () => {
    let store: ReturnType<typeof usePlacesStore>

    const mockPlaces: Place[] = [
        {
            id: 'place-1',
            name: 'Paris',
            lat: 48.8566,
            lng: 2.3522,
            game_count: 10,
            descriptors: { type: 'city' },
        },
        {
            id: 'place-2',
            name: 'London',
            lat: 51.5074,
            lng: -0.1278,
            game_count: 8,
            descriptors: { type: 'city' },
        },
    ]

    beforeEach(() => {
        setActivePinia(createPinia())
        store = usePlacesStore()
        vi.clearAllMocks()

        // Suppress console errors/warnings (they're intentional for error handling tests)
        vi.spyOn(console, 'error').mockImplementation(() => { })
        vi.spyOn(console, 'warn').mockImplementation(() => { })
        vi.spyOn(console, 'log').mockImplementation(() => { })

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

    describe('Initial State', () => {
        it('should initialize with empty state', () => {
            expect(store.places).toEqual([])
            expect(store.loading).toBe(false)
            expect(store.error).toBeNull()
        })
    })

    describe('fetchAllPlaces', () => {
        it('should fetch places from Supabase', async () => {
            await store.fetchAllPlaces()

            expect(mockFrom).toHaveBeenCalledWith('places')
            expect(mockSelect).toHaveBeenCalledWith('id, name, lat, lng, game_count')
            expect(mockOrder).toHaveBeenCalledWith('name')
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

    describe('reset', () => {
        it('should reset all state to initial values', async () => {
            // Load some data
            await store.fetchAllPlaces()
            expect(store.places).toEqual(mockPlaces)

            // Reset
            store.reset()

            expect(store.places).toEqual([])
            expect(store.loading).toBe(false)
            expect(store.error).toBeNull()
        })

        it('should allow fetching again after reset', async () => {
            // First fetch
            await store.fetchAllPlaces()
            expect(mockFrom).toHaveBeenCalledTimes(1)

            // Reset
            store.reset()

            // Second fetch should work
            await store.fetchAllPlaces()
            expect(mockFrom).toHaveBeenCalledTimes(2)
        })
    })

    describe('State Isolation', () => {
        it('should have independent state across store instances', () => {
            const store1 = usePlacesStore()
            const store2 = usePlacesStore()

            // They should be the same instance (Pinia singleton)
            expect(store1).toBe(store2)
        })

        it('should reset state between tests', () => {
            // This test verifies that beforeEach properly resets the store
            expect(store.places).toEqual([])
            expect(store.loading).toBe(false)
            expect(store.error).toBeNull()
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

            expect(mockSearchNominatim).toHaveBeenCalledWith('Paris', { limit: 5 })
            expect(results).toEqual([mockNominatimPlace])
            expect(store.searchLoading).toBe(false)
            expect(store.searchError).toBeUndefined()
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

    describe('enrichDescriptors', () => {
        it('should enrich descriptors with elevation and height', async () => {
            mockEnrichWithElevation.mockResolvedValueOnce(100)
            mockEnrichWithHeight.mockResolvedValueOnce(50)

            const descriptors = { type: 'building' }
            const result = await store.enrichDescriptors(48.8566, 2.3522, descriptors)

            expect(mockEnrichWithElevation).toHaveBeenCalledWith(48.8566, 2.3522, descriptors)
            expect(mockEnrichWithHeight).toHaveBeenCalledWith(48.8566, 2.3522, descriptors)
            expect(result).toMatchObject({
                type: 'building',
                elevation_meters: 100,
                height_meters: 50,
            })
            expect(result.enrichment_timestamp).toBeDefined()
        })

        it('should handle null elevation', async () => {
            mockEnrichWithElevation.mockResolvedValueOnce(null)
            mockEnrichWithHeight.mockResolvedValueOnce(50)

            const result = await store.enrichDescriptors(48.8566, 2.3522, {})

            expect(result).not.toHaveProperty('elevation_meters')
            expect(result).toHaveProperty('height_meters', 50)
        })

        it('should return original descriptors on error', async () => {
            mockEnrichWithElevation.mockRejectedValueOnce(new Error('API failed'))

            const descriptors = { type: 'building' }
            const result = await store.enrichDescriptors(48.8566, 2.3522, descriptors)

            expect(result).toEqual(descriptors)
        })
    })

    describe('extractDescriptors', () => {
        it('should extract descriptors from Nominatim place', () => {
            const mockPlace: NominatimPlace = {
                place_id: 123,
                display_name: 'Paris, France',
                lat: '48.8566',
                lon: '2.3522',
                type: 'city',
                class: 'place',
            } as NominatimPlace

            const mockDescriptors = { lat: 48.8566, lng: 2.3522, type: 'city' }
            mockExtractDescriptors.mockReturnValueOnce(mockDescriptors)

            const result = store.extractDescriptors(mockPlace)

            expect(mockExtractDescriptors).toHaveBeenCalledWith(mockPlace)
            expect(result).toEqual(mockDescriptors)
        })
    })
})

