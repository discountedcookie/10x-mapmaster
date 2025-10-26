import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { axe } from '../setup'

// Import components to test for accessibility
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'
import GameResultCard from '@/components/game/GameResultCard.vue'

describe('Accessibility Tests', () => {
  describe('GameQuestionCard', () => {
    it('should not have any accessibility violations', async () => {
      const wrapper = mount(GameQuestionCard, {
        props: {
          question: 'Is this place in Europe?',
          questionNumber: 1,
          totalQuestions: 5,
        },
      })

      const results = await axe(wrapper.element as HTMLElement)
      expect(results).toHaveNoViolations()
    })
  })

  describe('GameResultCard', () => {
    it('should not have any accessibility violations with high confidence', async () => {
      const wrapper = mount(GameResultCard, {
        props: {
          place: {
            id: '1',
            name: 'Paris',
            country: 'France',
            latitude: 48.8566,
            longitude: 2.3522,
            confidence: 0.95,
            percentile: 95,
          },
          isCorrect: true,
        },
      })

      const results = await axe(wrapper.element as HTMLElement)
      expect(results).toHaveNoViolations()
    })

    it('should not have any accessibility violations with low confidence', async () => {
      const wrapper = mount(GameResultCard, {
        props: {
          place: {
            id: '2',
            name: 'London',
            country: 'United Kingdom',
            latitude: 51.5074,
            longitude: -0.1278,
            confidence: 0.45,
            percentile: 45,
          },
          isCorrect: false,
        },
      })

      const results = await axe(wrapper.element as HTMLElement)
      expect(results).toHaveNoViolations()
    })
  })
})
