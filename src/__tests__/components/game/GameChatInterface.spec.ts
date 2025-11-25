import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import GameChatInterface from '@/components/game/GameChatInterface.vue'
import type { GameState } from '@/stores/game'

describe('GameChatInterface', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('should reactively update messages when gameState prop changes', async () => {
    // Create initial game state
    const initialGameState: GameState = {
      sessionId: 'test-session',
      description: 'Test Place',
      status: 'active',
      nextTurn: 'ask',
      questionCount: 0,
      candidateCount: 100,
      confidenceGap: 0,
      candidates: [],
      semanticConstraint: null,
      needsSubmission: false,
      messages: [
        {
          id: '1',
          role: 'system',
          text: 'Initial message',
          type: 'info',
          timestamp: new Date().toISOString(),
        },
      ],
    }

    // Mount component with initial state
    const wrapper = mount(GameChatInterface, {
      props: {
        gameState: initialGameState,
      },
    })

    // Verify initial message is displayed
    expect(wrapper.text()).toContain('Initial message')
    expect(wrapper.text()).not.toContain('New message')

    // Create NEW game state object (simulating store replacement)
    const updatedGameState: GameState = {
      ...initialGameState,
      messages: [
        {
          id: '1',
          role: 'system',
          text: 'Initial message',
          type: 'info',
          timestamp: new Date().toISOString(),
        },
        {
          id: '2',
          role: 'system',
          text: 'New message',
          type: 'question',
          timestamp: new Date().toISOString(),
        },
      ],
    }

    // Update prop with new object (this is what the store does)
    await wrapper.setProps({ gameState: updatedGameState })

    // Verify new message is now displayed (this tests reactivity)
    expect(wrapper.text()).toContain('Initial message')
    expect(wrapper.text()).toContain('New message')
  })

  it('should display question buttons when last message is a question', async () => {
    const gameState: GameState = {
      sessionId: 'test-session',
      description: 'Test Place',
      status: 'active',
      nextTurn: 'ask',
      questionCount: 1,
      candidateCount: 50,
      confidenceGap: 0.2,
      candidates: [],
      semanticConstraint: null,
      needsSubmission: false,
      messages: [
        {
          id: '1',
          role: 'system',
          text: 'Is it in Europe?',
          type: 'question',
          timestamp: new Date().toISOString(),
        },
      ],
    }

    const wrapper = mount(GameChatInterface, {
      props: { gameState },
    })

    // Should show Yes/No buttons
    expect(wrapper.text()).toContain('Yes')
    expect(wrapper.text()).toContain('No')
  })

  it('should display guess buttons when last message is a guess', async () => {
    const gameState: GameState = {
      sessionId: 'test-session',
      description: 'Test Place',
      status: 'active',
      nextTurn: 'guess',
      questionCount: 5,
      candidateCount: 1,
      confidenceGap: 0.8,
      candidates: [],
      semanticConstraint: null,
      needsSubmission: false,
      messages: [
        {
          id: '1',
          role: 'system',
          text: 'Is it the Eiffel Tower?',
          type: 'guess',
          timestamp: new Date().toISOString(),
        },
      ],
    }

    const wrapper = mount(GameChatInterface, {
      props: { gameState },
    })

    // Should show guess confirmation buttons
    expect(wrapper.text()).toContain('Yes, correct!')
    expect(wrapper.text()).toContain('No, try again')
  })

  it('should display submit button when status is needs_submission', async () => {
    const gameState: GameState = {
      sessionId: 'test-session',
      description: 'Test Place',
      status: 'needs_submission',
      nextTurn: 'ask',
      questionCount: 3,
      candidateCount: 0,
      confidenceGap: 0,
      candidates: [],
      semanticConstraint: null,
      needsSubmission: true,
      messages: [
        {
          id: '1',
          role: 'system',
          text: "I couldn't find this place. Please submit it!",
          type: 'info',
          timestamp: new Date().toISOString(),
        },
      ],
    }

    const wrapper = mount(GameChatInterface, {
      props: { gameState },
    })

    // Should show submit button
    expect(wrapper.text()).toContain('Submit this place')
  })
})
