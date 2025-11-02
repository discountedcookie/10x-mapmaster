import { beforeEach, describe, expect, it } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameStore, MAX_QUESTIONS, LOW_CONFIDENCE_MIN, LOW_CONFIDENCE_MAX } from '@/stores/game'
import type { GameCandidate, GameResult } from '@/stores/game'

describe('useGameStore', () => {
    let store: ReturnType<typeof useGameStore>

    const mockCandidate: GameCandidate = {
        id: 'place-1',
        name: 'Test Place',
        lat: 48.8566,
        lng: 2.3522,
        confidence: 0.85,
    }

    const mockGameResult: GameResult = {
        place: {
            id: 'place-1',
            name: 'Eiffel Tower',
            lat: 48.8584,
            lng: 2.2945,
        },
        confidence: 0.95,
        questionsAsked: 3,
        userWon: true,
    }

    beforeEach(() => {
        setActivePinia(createPinia())
        store = useGameStore()
    })

    describe('Initial State', () => {
        it('should initialize with empty state', () => {
            expect(store.gameState).toBe('idle')
            expect(store.currentQuestion).toBeNull()
            expect(store.userDescription).toBe('')
            expect(store.candidates).toEqual([])
            expect(store.result).toBeNull()
            expect(store.loading).toBe(false)
            expect(store.error).toBeNull()
            expect(store.questionsAsked).toBe(0)
        })

        it('should have idempotent computed properties on init', () => {
            expect(store.isPlaying).toBe(false)
            expect(store.isCompleted).toBe(false)
            expect(store.topCandidate).toBeNull()
            expect(store.confidence).toBe(0)
            expect(store.topCandidates).toEqual([])
        })
    })

    describe('Computed Properties', () => {
        it('should calculate topCandidates correctly', () => {
            const candidates: GameCandidate[] = [
                { ...mockCandidate, id: 'place-1', confidence: 0.9 },
                { ...mockCandidate, id: 'place-2', confidence: 0.8 },
                { ...mockCandidate, id: 'place-3', confidence: 0.7 },
                { ...mockCandidate, id: 'place-4', confidence: 0.6 },
                { ...mockCandidate, id: 'place-5', confidence: 0.5 },
                { ...mockCandidate, id: 'place-6', confidence: 0.4 },
            ]

            store.setCandidates(candidates)

            expect(store.topCandidates).toHaveLength(5)
            expect(store.topCandidates[0].id).toBe('place-1')
            expect(store.topCandidates[4].id).toBe('place-5')
        })

        it('should return topCandidate as first candidate', () => {
            store.setCandidates([mockCandidate])

            expect(store.topCandidate).toEqual(mockCandidate)
        })

        it('should return null for topCandidate when no candidates', () => {
            expect(store.topCandidate).toBeNull()
        })

        it('should calculate confidence from top candidate', () => {
            store.setCandidates([{ ...mockCandidate, confidence: 0.85 }])

            expect(store.confidence).toBe(0.85)
        })

        it('should return 0 confidence when no candidates', () => {
            expect(store.confidence).toBe(0)
        })

        it('should track isPlaying state correctly', () => {
            expect(store.isPlaying).toBe(false)

            store.setGameState('playing')
            expect(store.isPlaying).toBe(true)

            store.setGameState('idle')
            expect(store.isPlaying).toBe(false)
        })

        it('should track isCompleted state correctly', () => {
            expect(store.isCompleted).toBe(false)

            store.setGameState('completed')
            expect(store.isCompleted).toBe(true)

            store.setGameState('idle')
            expect(store.isCompleted).toBe(false)
        })
    })

    describe('setGameState', () => {
        it('should update game state', () => {
            expect(store.gameState).toBe('idle')

            store.setGameState('playing')
            expect(store.gameState).toBe('playing')

            store.setGameState('completed')
            expect(store.gameState).toBe('completed')
        })
    })

    describe('setCurrentQuestion', () => {
        it('should set current question', () => {
            const question = 'Is it in Europe?'

            store.setCurrentQuestion(question)

            expect(store.currentQuestion).toBe(question)
        })

        it('should allow null questions', () => {
            store.setCurrentQuestion('Some question')
            store.setCurrentQuestion(null as any)

            expect(store.currentQuestion).toBeNull()
        })
    })

    describe('setUserDescription', () => {
        it('should set user description', () => {
            const description = 'A famous landmark in Paris'

            store.setUserDescription(description)

            expect(store.userDescription).toBe(description)
        })

        it('should handle empty descriptions', () => {
            store.setUserDescription('Initial')
            store.setUserDescription('')

            expect(store.userDescription).toBe('')
        })
    })

    describe('setCandidates', () => {
        it('should set candidates list', () => {
            const candidates = [
                { ...mockCandidate, id: 'place-1' },
                { ...mockCandidate, id: 'place-2' },
            ]

            store.setCandidates(candidates)

            expect(store.candidates).toEqual(candidates)
        })

        it('should allow empty candidates', () => {
            store.setCandidates([mockCandidate])
            store.setCandidates([])

            expect(store.candidates).toEqual([])
        })
    })

    describe('setResult', () => {
        it('should set game result and mark as completed', () => {
            store.setResult(mockGameResult)

            expect(store.result).toEqual(mockGameResult)
            expect(store.gameState).toBe('completed')
        })

        it('should update existing result', () => {
            const firstResult = { ...mockGameResult, confidence: 0.8 }
            const secondResult = { ...mockGameResult, confidence: 0.95 }

            store.setResult(firstResult)
            expect(store.result?.confidence).toBe(0.8)

            store.setResult(secondResult)
            expect(store.result?.confidence).toBe(0.95)
        })
    })

    describe('setLoading', () => {
        it('should set loading state', () => {
            expect(store.loading).toBe(false)

            store.setLoading(true)
            expect(store.loading).toBe(true)

            store.setLoading(false)
            expect(store.loading).toBe(false)
        })
    })

    describe('setError', () => {
        it('should set error message', () => {
            const errorMsg = 'Something went wrong'

            store.setError(errorMsg)

            expect(store.error).toBe(errorMsg)
        })

        it('should allow clearing errors with null', () => {
            store.setError('Error')
            expect(store.error).toBe('Error')

            store.setError(null)
            expect(store.error).toBeNull()
        })
    })

    describe('incrementQuestions', () => {
        it('should increment questions asked', () => {
            expect(store.questionsAsked).toBe(0)

            store.incrementQuestions()
            expect(store.questionsAsked).toBe(1)

            store.incrementQuestions()
            expect(store.questionsAsked).toBe(2)
        })

        it('should allow multiple increments', () => {
            for (let i = 0; i < MAX_QUESTIONS; i++) {
                store.incrementQuestions()
            }

            expect(store.questionsAsked).toBe(MAX_QUESTIONS)
        })
    })

    describe('reset', () => {
        it('should reset all game state', () => {
            // Set up a complex state
            store.setGameState('playing')
            store.setCurrentQuestion('Test question')
            store.setUserDescription('Test description')
            store.setCandidates([mockCandidate])
            store.setLoading(true)
            store.setError('Some error')
            store.incrementQuestions()

            // Reset
            store.reset()

            // Verify all state is reset
            expect(store.gameState).toBe('idle')
            expect(store.currentQuestion).toBeNull()
            expect(store.userDescription).toBe('')
            expect(store.candidates).toEqual([])
            expect(store.result).toBeNull()
            expect(store.loading).toBe(false)
            expect(store.error).toBeNull()
            expect(store.questionsAsked).toBe(0)
        })

        it('should handle reset after game completion', () => {
            store.setResult(mockGameResult)
            expect(store.gameState).toBe('completed')

            store.reset()

            expect(store.gameState).toBe('idle')
            expect(store.result).toBeNull()
        })
    })

    describe('Game Flow', () => {
        it('should support complete game flow', () => {
            // Start game
            store.setGameState('playing')
            store.setUserDescription('A famous tower')
            expect(store.isPlaying).toBe(true)

            // Set candidates after asking questions
            store.setCandidates([
                { ...mockCandidate, id: 'eiffel', confidence: 0.95 },
                { ...mockCandidate, id: 'bigben', confidence: 0.75 },
            ])
            expect(store.topCandidate?.id).toBe('eiffel')
            expect(store.confidence).toBe(0.95)

            // Complete game
            store.setResult(mockGameResult)
            expect(store.isCompleted).toBe(true)

            // Reset for next game
            store.reset()
            expect(store.isPlaying).toBe(false)
            expect(store.candidates).toEqual([])
        })
    })

    describe('Constants', () => {
        it('should export game constants', () => {
            expect(MAX_QUESTIONS).toBe(5)
            expect(LOW_CONFIDENCE_MIN).toBe(0.5)
            expect(LOW_CONFIDENCE_MAX).toBe(0.8)
        })
    })
})
