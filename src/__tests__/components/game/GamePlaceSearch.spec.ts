import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { mount, VueWrapper } from '@vue/test-utils'
import { i18n } from '../../setup'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import type { NominatimPlace } from '@/composables/usePlaces'

// Mock places store
const mockSearchPlaces = vi.fn()
vi.mock('@/stores/places', () => ({
    usePlacesStore: () => ({
        searchPlaces: mockSearchPlaces,
        searchLoading: false,
        searchError: undefined,
    }),
}))

describe('GamePlaceSearch', () => {
    let wrapper: VueWrapper

    const mockPlace: NominatimPlace = {
        place_id: 123,
        display_name: 'Paris, France',
        lat: '48.8566',
        lon: '2.3522',
        type: 'city',
        class: 'place',
        importance: 0.9,
    }

    beforeEach(() => {
        setActivePinia(createPinia())
        vi.clearAllMocks()
        vi.useFakeTimers()
        mockSearchPlaces.mockResolvedValue([mockPlace])
        wrapper = mount(GamePlaceSearch, {
            global: {
                plugins: [i18n],
            },
        })
    })

    afterEach(() => {
        vi.useRealTimers()
        wrapper.unmount()
    })

    it('should render search input', () => {
        const input = wrapper.find('input[type="text"]')
        expect(input.exists()).toBe(true)
        expect(input.attributes('placeholder')).toBe(i18n.global.t('game.place_search.placeholder'))
    })

    it('should display title and description', () => {
        expect(wrapper.text()).toContain(i18n.global.t('game.place_search.title'))
        expect(wrapper.text()).toContain(i18n.global.t('game.place_search.description'))
    })

    it('should debounce search queries', async () => {
        const input = wrapper.find('input')

        await input.setValue('Par')
        expect(mockSearchPlaces).not.toHaveBeenCalled()

        await input.setValue('Paris')
        expect(mockSearchPlaces).not.toHaveBeenCalled()

        // Advance time by 1 second (debounce period)
        await vi.advanceTimersByTimeAsync(1000)

        expect(mockSearchPlaces).toHaveBeenCalledTimes(1)
        expect(mockSearchPlaces).toHaveBeenCalledWith('Paris')
    })

    it('should display search results', async () => {
        const input = wrapper.find('input')

        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(1000)
        await wrapper.vm.$nextTick()

        expect(wrapper.text()).toContain('Paris, France')
        expect(wrapper.text()).toContain('48.8566, 2.3522')
    })

    it('should emit select event when place is clicked', async () => {
        const input = wrapper.find('input')

        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(1000)
        await wrapper.vm.$nextTick()

        const resultButton = wrapper.find('button[class*="p-3"]')
        await resultButton.trigger('click')

        expect(wrapper.emitted('select')).toBeTruthy()
        expect(wrapper.emitted('select')?.[0]).toEqual([mockPlace])
    })

    it('should emit cancel event when cancel button is clicked', async () => {
        const cancelButton = wrapper.findAll('button').find((btn) => btn.text() === i18n.global.t('common.cancel'))
        await cancelButton?.trigger('click')

        expect(wrapper.emitted('cancel')).toBeTruthy()
    })

    it('should clear results when query is empty', async () => {
        const input = wrapper.find('input')

        // First, add a query
        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(1000)
        await wrapper.vm.$nextTick()

        // Then clear it
        await input.setValue('')
        await wrapper.vm.$nextTick()

        // Results should be cleared without waiting for debounce
        expect(wrapper.findAll('button[class*="p-3"]')).toHaveLength(0)
    })

    it('should clear previous timeout when query changes', async () => {
        const input = wrapper.find('input')

        await input.setValue('Par')
        await vi.advanceTimersByTimeAsync(500)

        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(500)

        // Only one search should be triggered
        expect(mockSearchPlaces).not.toHaveBeenCalled()

        await vi.advanceTimersByTimeAsync(500)

        expect(mockSearchPlaces).toHaveBeenCalledTimes(1)
        expect(mockSearchPlaces).toHaveBeenCalledWith('Paris')
    })

    it('should display multiple search results', async () => {
        const mockPlaces: NominatimPlace[] = [
            {
                place_id: 123,
                display_name: 'Paris, France',
                lat: '48.8566',
                lon: '2.3522',
                type: 'city',
                class: 'place',
                importance: 0.9,
            },
            {
                place_id: 124,
                display_name: 'Paris, Texas, USA',
                lat: '33.6609',
                lon: '-95.5555',
                type: 'city',
                class: 'place',
                importance: 0.7,
            },
        ]

        mockSearchPlaces.mockResolvedValue(mockPlaces)

        const input = wrapper.find('input')
        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(1000)
        await wrapper.vm.$nextTick()

        const resultButtons = wrapper.findAll('button[class*="p-3"]')
        expect(resultButtons).toHaveLength(2)
        expect(wrapper.text()).toContain('Paris, France')
        expect(wrapper.text()).toContain('Paris, Texas, USA')
    })

    it('should handle search errors gracefully', async () => {
        mockSearchPlaces.mockRejectedValueOnce(new Error('Search failed'))

        const input = wrapper.find('input')
        await input.setValue('Paris')
        await vi.advanceTimersByTimeAsync(1000)
        await wrapper.vm.$nextTick()

        // Error is handled in store, component should not crash
        expect(wrapper.findAll('button[class*="p-3"]')).toHaveLength(0)
    })
})

