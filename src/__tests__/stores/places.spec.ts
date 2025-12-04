import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { usePlacesStore } from '@/stores/places'

// Mock Supabase - minimal stub to allow store initialization
vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        not: vi.fn(() => ({
          not: vi.fn(() => ({
            order: vi.fn(() => Promise.resolve({ data: [], error: null })),
          })),
        })),
      })),
    })),
  },
}))

// Mock lib/places functions
vi.mock('@/lib/places', () => ({
  searchPlaces: vi.fn(),
  extractDescriptors: vi.fn(),
}))

describe('usePlacesStore - Pure Logic', () => {
  let store: ReturnType<typeof usePlacesStore>

  beforeEach(() => {
    setActivePinia(createPinia())
    store = usePlacesStore()
    vi.clearAllMocks()
  })

  describe('reset', () => {
    it('should reset state to initial values', () => {
      // Set some state
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

      store.reset()

      expect(store.places).toEqual([])
      expect(store.loading).toBe(false)
      expect(store.error).toBe(null)
    })
  })
})
