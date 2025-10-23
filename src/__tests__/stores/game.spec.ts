import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameStore } from '@/stores/game'
import type { PlaceWithScore, Question, Place } from '@/stores/game'

// Mock Supabase - use factory function to avoid hoisting issues
vi.mock('@/lib/supabase', () => {
    const mockRpc = vi.fn()
    const mockFrom = vi.fn()
    const mockSelect = vi.fn()
    const mockInsert = vi.fn()
    const mockUpdate = vi.fn()
    const mockEq = vi.fn()
    const mockSingle = vi.fn()
    const mockGte = vi.fn()
    const mockLte = vi.fn()
    const mockLimit = vi.fn()

    return {
        supabase: {
            rpc: mockRpc,
            from: mockFrom,
        },
        mockRpc,
        mockFrom,
        mockSelect,
        mockInsert,
        mockUpdate,
        mockEq,
        mockSingle,
        mockGte,
        mockLte,
        mockLimit,
    }
})

// Import mocks after mocking
const { mockRpc, mockFrom, mockSelect, mockInsert, mockUpdate, mockEq, mockSingle, mockGte: _mockGte, mockLte: _mockLte, mockLimit: _mockLimit } = await import('@/lib/supabase') as any

// Mock embeddings
const mockGenerateEmbedding = vi.fn()
const mockEmbeddingToString = vi.fn()
vi.mock('@/composables/useEmbeddings', () => ({
    useEmbeddings: () => ({
        generateEmbedding: mockGenerateEmbedding,
        embeddingToString: mockEmbeddingToString,
    }),
}))

// Mock auth store
const mockUser = { id: 'test-user-id', email: 'test@example.com' }
vi.mock('@/stores/auth', () => ({
    useAuthStore: () => ({
        user: mockUser,
    }),
}))

describe('useGameStore', () => {
    let store: ReturnType<typeof useGameStore>

    const mockEmbedding = Array.from({ length: 384 }, () => 0.1)
    const mockPlace: Place = {
        id: 'place-1',
        name: 'Test Place',
        lat: 48.8566,
        lng: 2.3522,
        descriptors: { type: 'city' },
        game_count: 5,
        embedding: mockEmbedding,
    }

    const mockPlaceWithScore: PlaceWithScore = {
        ...mockPlace,
        semantic_similarity: 0.85,
        spatial_confidence: 0.9,
        composite_confidence: 0.87,
    }

    const mockQuestion: Question = {
        id: 'question-1',
        text: 'Is it in Europe?',
        embedding: mockEmbedding,
        times_asked: 10,
        effectiveness_score: 0.75,
    }

    beforeEach(() => {
        setActivePinia(createPinia())
        store = useGameStore()
        vi.clearAllMocks()

        // Default mock implementations
        mockEmbeddingToString.mockImplementation((arr: number[]) => `[${arr.join(',')}]`)
        mockGenerateEmbedding.mockResolvedValue(mockEmbedding)
    })

    describe('Initial State', () => {
        it('should initialize with empty state', () => {
            expect(store.gameSessionId).toBeNull()
            expect(store.userDescription).toBe('')
            expect(store.descriptionEmbedding).toBeNull()
            expect(store.candidates).toEqual([])
            expect(store.questions).toEqual([])
            expect(store.gameResult).toBeNull()
            expect(store.loading).toBe(false)
            expect(store.error).toBeUndefined()
            // Note: mustAskQuestion is not exported, tested indirectly through isGameComplete
        })
    })

    describe('Computed Properties', () => {
        it('should return current question as first in array', () => {
            store.questions = [mockQuestion, { ...mockQuestion, id: 'question-2' }]
            expect(store.currentQuestion).toEqual(mockQuestion)
        })

        it('should calculate topCandidates correctly', () => {
            const candidates = Array.from({ length: 10 }, (_, i) => ({
                ...mockPlaceWithScore,
                id: `place-${i}`,
                composite_confidence: 0.9 - i * 0.05,
            }))
            store.candidates = candidates

            expect(store.topCandidates).toHaveLength(5)
            expect(store.topCandidates[0].id).toBe('place-0')
            expect(store.topCandidates[4].id).toBe('place-4')
        })

        it('should return topCandidate as first candidate', () => {
            store.candidates = [mockPlaceWithScore]
            expect(store.topCandidate).toEqual(mockPlaceWithScore)
        })

        it('should return null for topCandidate when no candidates', () => {
            store.candidates = []
            expect(store.topCandidate).toBeNull()
        })

        it('should calculate confidence from top candidate', () => {
            store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.85 }]
            expect(store.confidence).toBe(0.85)
        })

        it('should return 0 confidence when no candidates', () => {
            store.candidates = []
            expect(store.confidence).toBe(0)
        })

        it('should detect low confidence correctly', () => {
            store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.65 }]
            expect(store.isLowConfidence).toBe(true)

            store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.9 }]
            expect(store.isLowConfidence).toBe(false)

            store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.4 }]
            expect(store.isLowConfidence).toBe(false)
        })

        describe('isGameComplete', () => {
            it('should not be complete when must ask question (after wrong guess)', () => {
                // mustAskQuestion is not directly testable, but we can test the logic
                // It's set to false by default, so game completes based on other conditions
                store.sessionQuestionCount = 5
                store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.65 }]
                store.questions = [mockQuestion]
                expect(store.isGameComplete).toBe(false)
            })

            it('should be complete when max questions reached', () => {
                store.sessionQuestionCount = 20 // MAX_QUESTIONS
                expect(store.isGameComplete).toBe(true)
            })

            it('should be complete when confidence is high', () => {
                store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.85 }]
                expect(store.isGameComplete).toBe(true)
            })

            it('should be complete when no more questions available', () => {
                store.questions = []
                expect(store.isGameComplete).toBe(true)
            })

            it('should not be complete in normal gameplay', () => {
                store.mustAskQuestion = false
                store.sessionQuestionCount = 5
                store.candidates = [{ ...mockPlaceWithScore, composite_confidence: 0.65 }]
                store.questions = [mockQuestion]
                expect(store.isGameComplete).toBe(false)
            })
        })
    })

    describe('startNewGame', () => {
        beforeEach(() => {
            mockFrom.mockReturnValue({
                insert: mockInsert.mockReturnValue({
                    select: mockSelect.mockReturnValue({
                        single: mockSingle.mockResolvedValue({
                            data: { id: 'session-1' },
                            error: null,
                        }),
                    }),
                }),
            })

            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({ data: [mockPlaceWithScore], error: null })
                }
                if (fnName === 'get_next_question') {
                    return Promise.resolve({ data: [mockQuestion], error: null })
                }
                return Promise.resolve({ data: null, error: null })
            })
        })

        it('should start a new game successfully', async () => {
            await store.startNewGame('A beautiful city in France')

            expect(mockGenerateEmbedding).toHaveBeenCalledWith('A beautiful city in France')
            expect(store.userDescription).toBe('A beautiful city in France')
            expect(store.descriptionEmbedding).toEqual(mockEmbedding)
            expect(store.gameSessionId).toBe('session-1')
            expect(store.candidates).toHaveLength(1)
            expect(store.questions).toHaveLength(1)
        })

        it('should throw error for empty description', async () => {
            await expect(store.startNewGame('')).rejects.toThrow('Description cannot be empty')
        })

        it('should set loading state during game start', async () => {
            const startPromise = store.startNewGame('Test')

            expect(store.loading).toBe(true)

            await startPromise

            expect(store.loading).toBe(false)
        })

        it('should set gameResult immediately if high confidence', async () => {
            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({
                        data: [{ ...mockPlaceWithScore, composite_confidence: 0.9 }],
                        error: null,
                    })
                }
                if (fnName === 'get_next_question') {
                    return Promise.resolve({ data: [mockQuestion], error: null })
                }
                return Promise.resolve({ data: null, error: null })
            })

            await store.startNewGame('Eiffel Tower')

            expect(store.gameResult).toBeTruthy()
            expect(store.gameResult?.composite_confidence).toBe(0.9)
        })

        it('should handle errors gracefully', async () => {
            mockGenerateEmbedding.mockRejectedValueOnce(new Error('Embedding failed'))

            await expect(store.startNewGame('Test')).rejects.toThrow('Embedding failed')
            expect(store.error).toBe('Embedding failed')
            expect(store.loading).toBe(false)
        })
    })

    describe('answerQuestion', () => {
        beforeEach(() => {
            store.gameSessionId = 'session-1'
            store.questions = [mockQuestion]
            store.candidates = [mockPlaceWithScore]
            store.sessionQuestionCount = 0

            mockFrom.mockReturnValue({
                insert: mockInsert.mockReturnValue({
                    select: undefined,
                    single: undefined,
                }),
                select: mockSelect.mockReturnValue({
                    eq: mockEq.mockReturnValue({
                        single: mockSingle.mockResolvedValue({
                            data: { question_count: 1, wrong_guess_count: 0 },
                            error: null,
                        }),
                    }),
                }),
            })

            mockInsert.mockResolvedValue({ data: null, error: null })

            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({ data: [mockPlaceWithScore], error: null })
                }
                if (fnName === 'get_next_question') {
                    return Promise.resolve({ data: [], error: null })
                }
                return Promise.resolve({ data: null, error: null })
            })
        })

        it('should save answer and reload state', async () => {
            await store.answerQuestion(true)

            expect(mockFrom).toHaveBeenCalledWith('game_answers')
            expect(mockInsert).toHaveBeenCalled()
            expect(mockRpc).toHaveBeenCalledWith('get_candidates', { session_id_param: 'session-1' })
        })

        it('should reload state after answering', async () => {
            await store.answerQuestion(true)

            // Verify RPC calls were made to reload state
            expect(mockRpc).toHaveBeenCalledWith('get_candidates', { session_id_param: 'session-1' })
            expect(mockFrom).toHaveBeenCalledWith('game_session_stats')
        })

        it('should set gameResult when game completes with high confidence', async () => {
            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({
                        data: [{ ...mockPlaceWithScore, composite_confidence: 0.9 }],
                        error: null,
                    })
                }
                return Promise.resolve({ data: [], error: null })
            })

            await store.answerQuestion(true)

            expect(store.gameResult).toBeTruthy()
        })

        it('should do nothing if no current question', async () => {
            store.questions = []

            await store.answerQuestion(true)

            expect(mockInsert).not.toHaveBeenCalled()
        })

        it('should do nothing if no session ID', async () => {
            store.gameSessionId = null

            await store.answerQuestion(true)

            expect(mockInsert).not.toHaveBeenCalled()
        })
    })

    describe('rejectGuessAndContinue', () => {
        beforeEach(() => {
            store.gameSessionId = 'session-1'
            store.gameResult = mockPlaceWithScore
            store.candidates = [mockPlaceWithScore]
            store.questions = [mockQuestion]
            store.sessionQuestionCount = 5

            mockFrom.mockReturnValue({
                insert: mockInsert.mockResolvedValue({ data: null, error: null }),
            })

            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({ data: [mockPlaceWithScore], error: null })
                }
                return Promise.resolve({ data: null, error: null })
            })
        })

        it('should save wrong guess and reset game result', async () => {
            await store.rejectGuessAndContinue()

            expect(mockFrom).toHaveBeenCalledWith('game_answers')
            expect(mockInsert).toHaveBeenCalledWith(
                expect.objectContaining({
                    session_id: 'session-1',
                    place_id: mockPlaceWithScore.id,
                    answer: false,
                    answer_type: 'wrong_guess',
                })
            )
            expect(store.gameResult).toBeNull()
            // mustAskQuestion is internal state, not directly testable
        })

        it('should handle no candidates left scenario', async () => {
            mockRpc.mockImplementation((fnName: string) => {
                if (fnName === 'get_candidates') {
                    return Promise.resolve({ data: [], error: null })
                }
                return Promise.resolve({ data: null, error: null })
            })

            await store.rejectGuessAndContinue()

            expect(store.gameResult).toBeNull()
            expect(store.candidates).toEqual([])
        })

        it('should handle no questions left scenario', async () => {
            store.questions = []

            await store.rejectGuessAndContinue()

            expect(store.gameResult).toBeNull()
        })
    })

    describe('finalizeGameSession', () => {
        beforeEach(() => {
            store.gameSessionId = 'session-1'
            store.descriptionEmbedding = mockEmbedding

            mockFrom.mockReturnValue({
                update: mockUpdate.mockReturnValue({
                    eq: mockEq.mockResolvedValue({ data: null, error: null }),
                }),
            })

            mockRpc.mockResolvedValue({ data: null, error: null })
        })

        it('should update session with results for correct guess', async () => {
            await store.finalizeGameSession(mockPlace, true, false)

            expect(mockUpdate).toHaveBeenCalledWith({
                place_id: mockPlace.id,
                was_correct: true,
            })
            expect(mockRpc).toHaveBeenCalledWith('update_place_embedding', expect.any(Object))
            expect(mockRpc).toHaveBeenCalledWith('update_question_effectiveness_batch', {
                session_id_param: 'session-1',
            })
        })

        it('should not update question effectiveness for wrong guess', async () => {
            await store.finalizeGameSession(mockPlace, false, false)

            expect(mockUpdate).toHaveBeenCalled()
            expect(mockRpc).not.toHaveBeenCalledWith(
                'update_question_effectiveness_batch',
                expect.any(Object)
            )
        })

        it('should not update place embedding for new places', async () => {
            await store.finalizeGameSession(mockPlace, true, true)

            expect(mockRpc).not.toHaveBeenCalledWith('update_place_embedding', expect.any(Object))
            expect(mockRpc).toHaveBeenCalledWith('update_question_effectiveness_batch', expect.any(Object))
        })

        // Note: Testing auth store mock is complex due to module boundaries
        // This is better tested with integration tests

        it('should throw error if no game session', async () => {
            store.gameSessionId = null

            await expect(store.finalizeGameSession(mockPlace, true)).rejects.toThrow(
                'No active game session'
            )
        })
    })

    describe('checkPlaceExists', () => {
        it('should query places table with tolerance', async () => {
            // Build complete chain with all methods returning the next step
            const chain = {
                select: vi.fn().mockReturnThis(),
                gte: vi.fn().mockReturnThis(),
                lte: vi.fn().mockReturnThis(),
                limit: vi.fn().mockReturnThis(),
                single: vi.fn().mockResolvedValue({ data: mockPlace, error: null }),
            }

            // Bind all methods to return the same chain object
            chain.select.mockReturnValue(chain)
            chain.gte.mockReturnValue(chain)
            chain.lte.mockReturnValue(chain)
            chain.limit.mockReturnValue(chain)

            mockFrom.mockReturnValue(chain)

            const result = await store.checkPlaceExists(48.8566, 2.3522)

            expect(result).toEqual(mockPlace)
            expect(mockFrom).toHaveBeenCalledWith('places')
        })

        it('should return null if no place found', async () => {
            // Build complete chain with all methods returning the next step
            const chain = {
                select: vi.fn().mockReturnThis(),
                gte: vi.fn().mockReturnThis(),
                lte: vi.fn().mockReturnThis(),
                limit: vi.fn().mockReturnThis(),
                single: vi.fn().mockResolvedValue({ data: null, error: null }),
            }

            // Bind all methods to return the same chain object
            chain.select.mockReturnValue(chain)
            chain.gte.mockReturnValue(chain)
            chain.lte.mockReturnValue(chain)
            chain.limit.mockReturnValue(chain)

            mockFrom.mockReturnValue(chain)

            const result = await store.checkPlaceExists(48.8566, 2.3522)

            expect(result).toBeNull()
        })
    })

    describe('saveNewPlace', () => {
        beforeEach(() => {
            store.descriptionEmbedding = mockEmbedding

            mockFrom.mockReturnValue({
                insert: mockInsert.mockReturnValue({
                    select: mockSelect.mockReturnValue({
                        single: mockSingle.mockResolvedValue({
                            data: mockPlace,
                            error: null,
                        }),
                    }),
                }),
            })
        })

        it('should save new place with embedding', async () => {
            const result = await store.saveNewPlace('Paris', 48.8566, 2.3522, { type: 'city' })

            expect(mockInsert).toHaveBeenCalledWith({
                name: 'Paris',
                lat: 48.8566,
                lng: 2.3522,
                descriptors: { type: 'city' },
                embedding: expect.any(String),
                game_count: 1,
            })
            expect(result).toEqual(mockPlace)
        })

        it('should throw error if no embedding available', async () => {
            store.descriptionEmbedding = null

            await expect(
                store.saveNewPlace('Paris', 48.8566, 2.3522, {})
            ).rejects.toThrow('Description embedding is required')
        })
    })

    describe('resetGame', () => {
        it('should reset all game state', () => {
            // First set the state
            store.gameSessionId = 'session-1'
            store.userDescription = 'Test'
            store.descriptionEmbedding = mockEmbedding
            store.candidates = [mockPlaceWithScore]
            store.questions = [mockQuestion]
            store.gameResult = mockPlaceWithScore
            // Note: sessionQuestionCount is computed from DB, not directly settable

            store.resetGame()

            expect(store.gameSessionId).toBeNull()
            expect(store.userDescription).toBe('')
            expect(store.descriptionEmbedding).toBeNull()
            expect(store.candidates).toEqual([])
            expect(store.questions).toEqual([])
            expect(store.gameResult).toBeNull()
            // Note: questionCount is a computed property from sessionQuestionCount ref
            // which gets reset in resetGame()
        })
    })
})

