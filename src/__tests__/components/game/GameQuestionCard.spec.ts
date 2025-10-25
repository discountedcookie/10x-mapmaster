import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { i18n } from '../../setup'
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'

describe('GameQuestionCard', () => {
  const defaultProps = {
    question: 'Is it in Europe?',
    questionNumber: 5,
    totalQuestions: 20,
    candidatesCount: 15,
    confidence: 0.65,
    topCandidates: [
      { name: 'Paris', confidence: 0.65 },
      { name: 'London', confidence: 0.60 },
      { name: 'Berlin', confidence: 0.55 },
    ],
  }

  it('should render question text', () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain('Is it in Europe?')
  })

  it('should display question progress', () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain(i18n.global.t('game.question_card.question_number', { current: 5, total: 20 }))
  })

  it('should calculate progress percentage correctly', () => {
    const wrapper = mount(GameQuestionCard, {
      props: { ...defaultProps, questionNumber: 5, totalQuestions: 20 },
      global: {
        plugins: [i18n],
      },
    })

    // Progress should be 25% (5/20 * 100)
    const progress = wrapper.findComponent({ name: 'Progress' })
    expect(progress.props('modelValue')).toBe(25)
  })

  it('should display candidates count with singular form', () => {
    const wrapper = mount(GameQuestionCard, {
      props: { ...defaultProps, candidatesCount: 1, topCandidates: undefined },
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain(i18n.global.t('game.question_card.candidates_remaining', { count: 1 }))
  })

  it('should display candidates count with plural form', () => {
    const wrapper = mount(GameQuestionCard, {
      props: { ...defaultProps, candidatesCount: 15, topCandidates: undefined },
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain(i18n.global.t('game.question_card.candidates_remaining', { count: 15 }))
  })

  it('should display confidence badge when provided', () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain(i18n.global.t('game.question_card.top_candidates'))
    const confidenceBadge = wrapper.findComponent({ name: 'ConfidenceBadge' })
    expect(confidenceBadge.exists()).toBe(true)
    expect(confidenceBadge.props('confidence')).toBe(0.65)
  })

  it('should not display confidence when not provided', () => {
    const propsWithoutConfidence = { ...defaultProps, topCandidates: undefined }
    delete propsWithoutConfidence.confidence

    const wrapper = mount(GameQuestionCard, {
      props: propsWithoutConfidence,
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).not.toContain(i18n.global.t('game.question_card.top_candidates'))
    const confidenceBadge = wrapper.findComponent({ name: 'ConfidenceBadge' })
    expect(confidenceBadge.exists()).toBe(false)
  })

  it('should emit answer event with true when Yes is clicked', async () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    const yesButton = wrapper.findAll('button').find((btn) => btn.text() === i18n.global.t('game.yes'))
    await yesButton?.trigger('click')

    expect(wrapper.emitted('answer')).toBeTruthy()
    expect(wrapper.emitted('answer')?.[0]).toEqual([true])
  })

  it('should emit answer event with false when No is clicked', async () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    const noButton = wrapper.findAll('button').find((btn) => btn.text() === i18n.global.t('game.no'))
    await noButton?.trigger('click')

    expect(wrapper.emitted('answer')).toBeTruthy()
    expect(wrapper.emitted('answer')?.[0]).toEqual([false])
  })

  it('should render Yes and No buttons', () => {
    const wrapper = mount(GameQuestionCard, {
      props: defaultProps,
      global: {
        plugins: [i18n],
      },
    })

    const buttons = wrapper.findAll('button')
    const yesButton = buttons.find((btn) => btn.text() === i18n.global.t('game.yes'))
    const noButton = buttons.find((btn) => btn.text() === i18n.global.t('game.no'))

    expect(yesButton).toBeDefined()
    expect(noButton).toBeDefined()
  })

  it('should handle 0 candidates', () => {
    const wrapper = mount(GameQuestionCard, {
      props: { ...defaultProps, candidatesCount: 0, topCandidates: undefined },
      global: {
        plugins: [i18n],
      },
    })

    expect(wrapper.text()).toContain(i18n.global.t('game.question_card.candidates_remaining', { count: 0 }))
  })

  it('should show 100% progress when on last question', () => {
    const wrapper = mount(GameQuestionCard, {
      props: { ...defaultProps, questionNumber: 20, totalQuestions: 20 },
      global: {
        plugins: [i18n],
      },
    })

    const progress = wrapper.findComponent({ name: 'Progress' })
    expect(progress.props('modelValue')).toBe(100)
  })
})



