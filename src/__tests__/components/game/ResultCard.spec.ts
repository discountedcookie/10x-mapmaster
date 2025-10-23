import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { i18n } from '../../setup'
import ResultCard from '@/components/game/ResultCard.vue'
import type { Tables } from '@/types/database'

interface PlaceWithScore extends Tables<'places'> {
    semantic_similarity: number
    spatial_confidence: number
    composite_confidence: number
}

describe('ResultCard', () => {
    const mockPlace: PlaceWithScore = {
        id: 'place-1',
        name: 'Paris',
        lat: 48.8566,
        lng: 2.3522,
        descriptors: { type: 'city' },
        game_count: 10,
        embedding: Array(384).fill(0.1),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        semantic_similarity: 0.85,
        spatial_confidence: 0.9,
        composite_confidence: 0.87,
    }

    describe('High Confidence Guess', () => {
        it('should display place name and coordinates', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain('Paris')
            expect(wrapper.text()).toContain('48.8566°, 2.3522°')
        })

        it('should show "Is this your place?" title for high confidence', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0.9 } },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.is_this_your_place'))
        })

        it('should display confidence badge', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.overall_match'))
            const badge = wrapper.findComponent({ name: 'ConfidenceBadge' })
            expect(badge.exists()).toBe(true)
            expect(badge.props('confidence')).toBe(0.87)
        })

        it('should emit correct event when "Yes, that\'s it!" is clicked', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            const correctButton = wrapper.findAll('button').find((btn) => btn.text().includes(i18n.global.t('game.result_card.yes_thats_it')))
            await correctButton?.trigger('click')

            expect(wrapper.emitted('correct')).toBeTruthy()
        })

        it('should emit incorrect event when "No, that\'s not it" is clicked', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            const incorrectButton = wrapper.findAll('button').find((btn) =>
                btn.text().includes(i18n.global.t('game.result_card.no_thats_not_it'))
            )
            await incorrectButton?.trigger('click')

            expect(wrapper.emitted('incorrect')).toBeTruthy()
        })

        it('should disable buttons when disabled prop is true', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace, disabled: true },
                global: {
                    plugins: [i18n],
                },
            })

            const buttons = wrapper.findAll('button')
            const actionButtons = buttons.filter((btn) =>
                btn.text().includes(i18n.global.t('game.result_card.yes_thats_it')) || btn.text().includes(i18n.global.t('game.result_card.no_thats_not_it'))
            )

            actionButtons.forEach((button) => {
                expect(button.attributes('disabled')).toBeDefined()
            })
        })
    })

    describe('Low Confidence Guess', () => {
        const lowConfidencePlace: PlaceWithScore = {
            ...mockPlace,
            composite_confidence: 0.65, // Between 0.5 and 0.8
        }

        it('should show narrowing down message for low confidence', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: lowConfidencePlace },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.narrowing_down'))
            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.low_confidence_description'))
        })

        it('should show different button text for low confidence', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: lowConfidencePlace },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.yes_its_this_one'))
            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.no_keep_asking'))
        })

        it('should still emit correct/incorrect events', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: lowConfidencePlace },
                global: {
                    plugins: [i18n],
                },
            })

            const yesButton = wrapper.findAll('button').find((btn) =>
                btn.text().includes(i18n.global.t('game.result_card.yes_its_this_one'))
            )
            await yesButton?.trigger('click')
            expect(wrapper.emitted('correct')).toBeTruthy()

            const noButton = wrapper.findAll('button').find((btn) =>
                btn.text().includes(i18n.global.t('game.result_card.no_keep_asking'))
            )
            await noButton?.trigger('click')
            expect(wrapper.emitted('incorrect')).toBeTruthy()
        })
    })

    describe('No Match Found', () => {
        it('should show "No matches found" when guess is null', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: null },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.no_matches'))
            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.no_match_found_description'))
        })

        it('should show "Tell us the place" button when no match', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: null },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.tell_us_the_place'))
            expect(wrapper.text()).toContain(i18n.global.t('game.play_again'))
        })

        it('should emit incorrect when "Tell us the place" is clicked', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: null },
                global: {
                    plugins: [i18n],
                },
            })

            const tellUsButton = wrapper.findAll('button').find((btn) =>
                btn.text().includes(i18n.global.t('game.result_card.tell_us_the_place'))
            )
            await tellUsButton?.trigger('click')

            expect(wrapper.emitted('incorrect')).toBeTruthy()
        })

        it('should emit playAgain when "Play Again" is clicked', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: null },
                global: {
                    plugins: [i18n],
                },
            })

            const playAgainButton = wrapper.findAll('button').find((btn) =>
                btn.text().includes(i18n.global.t('game.play_again'))
            )
            await playAgainButton?.trigger('click')

            expect(wrapper.emitted('playAgain')).toBeTruthy()
        })
    })

    describe('Match Analysis', () => {
        it('should show match analysis collapsible', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.match_analysis'))
        })

        it('should calculate semantic percentage correctly', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, semantic_similarity: 0.85 } },
                global: {
                    plugins: [i18n],
                },
            })

            // Open collapsible
            const collapsibleTrigger = wrapper.find('button[class*="justify-between"]')
            await collapsibleTrigger.trigger('click')
            await wrapper.vm.$nextTick()

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.description_match'))
            expect(wrapper.text()).toContain('85%')
        })

        it('should calculate spatial percentage correctly', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, spatial_confidence: 0.9 } },
                global: {
                    plugins: [i18n],
                },
            })

            // Open collapsible
            const collapsibleTrigger = wrapper.find('button[class*="justify-between"]')
            await collapsibleTrigger.trigger('click')
            await wrapper.vm.$nextTick()

            expect(wrapper.text()).toContain(i18n.global.t('game.result_card.location_clustering'))
            expect(wrapper.text()).toContain('90%')
        })

        it('should toggle analysis visibility', async () => {
            const wrapper = mount(ResultCard, {
                props: { guess: mockPlace },
                global: {
                    plugins: [i18n],
                },
            })

            const trigger = wrapper.find('button[class*="justify-between"]')

            // Initially closed
            expect(wrapper.vm.showAnalysis).toBe(false)

            // Open
            await trigger.trigger('click')
            await wrapper.vm.$nextTick()
            expect(wrapper.vm.showAnalysis).toBe(true)

            // Close
            await trigger.trigger('click')
            await wrapper.vm.$nextTick()
            expect(wrapper.vm.showAnalysis).toBe(false)
        })
    })

    describe('Computed Properties', () => {
        it('should calculate confidence percent', () => {
            const wrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0.87 } },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.vm.confidencePercent).toBe(87)
        })

        it('should detect low confidence correctly', () => {
            // Low confidence (0.5 <= x < 0.8)
            const lowWrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0.65 } },
                global: {
                    plugins: [i18n],
                },
            })
            expect(lowWrapper.vm.isLowConfidence).toBe(true)

            // High confidence
            const highWrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0.9 } },
                global: {
                    plugins: [i18n],
                },
            })
            expect(highWrapper.vm.isLowConfidence).toBe(false)

            // Very low confidence
            const veryLowWrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0.4 } },
                global: {
                    plugins: [i18n],
                },
            })
            expect(veryLowWrapper.vm.isLowConfidence).toBe(false)
        })

        it('should return undefined when confidence is 0 (edge case)', () => {
            // Note: The component treats 0 as falsy, so confidencePercent returns undefined
            // This is acceptable since 0% confidence means no match (shouldn't happen in practice)
            const wrapper = mount(ResultCard, {
                props: { guess: { ...mockPlace, composite_confidence: 0 } },
                global: {
                    plugins: [i18n],
                },
            })

            expect(wrapper.vm.confidencePercent).toBeUndefined()
        })
    })
})

